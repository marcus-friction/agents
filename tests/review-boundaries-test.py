"""Regression tests for registry and managed-state trust boundaries."""
import copy
import hashlib
import importlib.util
import json
import os
import re
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('eval_runner', ROOT / 'tests/agent-evals/runner.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class SnapshotCompatibility(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source'
        (self.source / '.agents/skills').mkdir(parents=True)
        (self.source / 'scripts').mkdir()
        (self.source / '.cursor').mkdir()
        (self.source / '.cursor/skills').symlink_to('../.agents/skills')
        (self.source / 'scripts/register-skills.sh').write_text('#!/bin/bash\nexit 0\n')
        self.git('init', '-q', '-b', 'master')
        self.git('config', 'user.name', 'Test')
        self.git('config', 'user.email', 'test@example.invalid')
        self.marker = self.source / '.agents/skills/marker'
        self.marker.write_text('first')
        self.first = self.commit()
        self.marker.write_text('second')
        self.second = self.commit()
        self.home = self.root / 'home'
        self.home.mkdir(mode=0o700)
        self.dest = self.home / '.agent-ecosystem'
        binary = self.root / 'bin'
        binary.mkdir()
        real_git = shutil.which('git')
        wrapper = binary / 'git'
        wrapper.write_text('#!/bin/bash\nargs=()\nfor arg in "$@"; do\n'
                           'if [ "$arg" = https://github.com/marcus-friction/agents.git ]; then arg="$TEST_REMOTE"; fi\n'
                           'args+=("$arg")\ndone\nexec "$TEST_REAL_GIT" "${args[@]}"\n')
        wrapper.chmod(0o700)
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(binary) + ':' + os.environ['PATH'],
                        TEST_REMOTE=str(self.source), TEST_REAL_GIT=real_git)

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.source), *args], stderr=subprocess.DEVNULL).decode().strip()

    def commit(self):
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')
        return self.git('rev-parse', 'HEAD')

    def install(self, *args):
        return subprocess.run(['bash', str(ROOT / 'scripts/install-user-snapshot.sh'),
                               '--destination', str(self.dest), '--adapters', 'cursor', *args],
                              env=self.env, capture_output=True, timeout=30)

    def test_edge_rewind_preserves_installed_snapshot(self):
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.git('reset', '--hard', self.first)
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b'fast-forward', result.stderr)
        self.assertEqual((self.dest / '.agents/skills/marker').read_text(), 'second')

    def test_complete_repository_payload_installs(self):
        paths = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', '-z',
                                         '--cached', '--others', '--exclude-standard']).split(b'\0')
        for raw in set(paths):
            if not raw:
                continue
            relative = os.fsdecode(raw)
            path = ROOT / relative
            if not path.exists() and not path.is_symlink():
                continue
            destination = self.source / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            if destination.is_symlink():
                destination.unlink()
            shutil.copy2(path, destination, follow_symlinks=False)
        sha = self.commit()
        result = self.install('--ref', sha)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.dest / '.agents/skills/plan/SKILL.md').is_file())
        self.assertFalse((self.dest / '.cursor/skills').exists())
        self.assertEqual((self.home / '.cursor/skills').readlink(), self.dest / '.agents/skills')

    def test_legacy_checkout_migrates_with_recovery(self):
        subprocess.run(['git', 'clone', '-q', str(self.source), str(self.dest)], check=True)
        result = self.install('--ref', self.second)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.dest / '.agents-ecosystem-install-state-v2').is_file())
        self.assertFalse((self.dest / '.git').exists())
        self.assertTrue(list(self.home.glob('*.legacy-*/previous/.git')))

    def test_dirty_legacy_checkout_is_preserved(self):
        subprocess.run(['git', 'clone', '-q', str(self.source), str(self.dest)], check=True)
        marker = self.dest / '.agents/skills/marker'
        marker.write_text('local edit')
        result = self.install('--ref', self.second)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), 'local edit')
        self.assertTrue((self.dest / '.git').is_dir())

    def test_legacy_mode_and_symlink_edits_are_preserved(self):
        subprocess.run(['git', 'clone', '-q', str(self.source), str(self.dest)], check=True)
        marker = self.dest / '.agents/skills/marker'
        marker.chmod(0o755)
        result = self.install('--ref', self.second)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(marker.stat().st_mode & 0o100)
        marker.unlink()
        marker.symlink_to(self.marker)
        result = self.install('--ref', self.second)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(marker.is_symlink())

    def test_shared_destination_parent_is_rejected(self):
        self.home.chmod(0o777)
        result = self.install('--ref', self.second)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.dest.exists())
        self.home.chmod(0o700)

    def test_bulk_source_keeps_private_directory_during_clone(self):
        script = (ROOT / 'scripts/install-into-repos.sh').read_text()
        function = re.search(r'(?ms)^materialize_release_source\(\) \{\n.*?^\}', script).group()
        installer = self.source / 'install.sh'
        installer.write_text('#!/bin/bash\nexit 0\n')
        installer.chmod(0o755)
        sha = self.commit()
        harness = '''set -eu
umask 077
mktemp() { command mktemp -d "$TEST_ROOT/bulk-source.XXXXXX"; }
source_git() {
  if [ "$1" = clone ] && [ ! -d "${@: -1}" ]; then
    echo 'private source root removed before clone' >&2; return 1
  fi
  git "$@"
}
'''
        result = subprocess.run(['bash', '-c', harness + function + '\nmaterialize_release_source\n'],
                                env=dict(os.environ, TEST_ROOT=str(self.root), SRC=str(self.source), RELEASE_REF=sha),
                                capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)


class Boundaries(unittest.TestCase):
    def test_previous_project_distribution_upgrades(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            archive = subprocess.check_output(['git', '-C', str(ROOT), 'archive',
                                               '4d599c0', '.agents'])
            subprocess.run(['tar', '-x', '-C', str(project)], input=archive, check=True)
            (project / '.agents/project').mkdir()
            (project / '.agents/project/context.md').write_text('project context')
            (project / '.agents/skills/local-only').mkdir()
            (project / '.agents/skills/local-only/SKILL.md').write_text('local skill')
            (project / 'README.md').write_text('project readme')
            result = subprocess.run(['bash', str(ROOT / 'install.sh'), '--from-local', str(ROOT)],
                                    cwd=project, capture_output=True, timeout=60)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((project / '.agents/.agents-ecosystem-managed-state-v2').is_file())
            self.assertFalse((project / '.agents/skills/ma-review').exists())
            self.assertEqual((project / '.agents/project/context.md').read_text(), 'project context')
            self.assertEqual((project / '.agents/skills/local-only/SKILL.md').read_text(), 'local skill')
            self.assertEqual((project / 'README.md').read_text(), 'project readme')

    def test_known_legacy_project_adoption(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, target = root / 'source', root / 'target'
            (source / 'skills/example').mkdir(parents=True)
            (target / 'skills/example').mkdir(parents=True)
            (target / 'skills/local').mkdir()
            (source / 'skills/example/SKILL.md').write_text('new')
            old = target / 'skills/example/SKILL.md'
            old.write_text('old')
            old.chmod(0o644)
            local = target / 'skills/local/SKILL.md'
            local.write_text('local')
            inventory = root / 'legacy.tsv'
            inventory.write_text(hashlib.sha256(b'old').hexdigest() + '\t644\tskills/example/SKILL.md\n')
            command = ['bash', str(ROOT / 'scripts/sync-managed-tree.sh'), '--legacy-manifest', str(inventory), str(source), str(target)]
            result = subprocess.run(command, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(old.read_text(), 'new')
            self.assertEqual(local.read_text(), 'local')
            (target / '.agents-ecosystem-managed-state-v2').unlink()
            old.write_text('local change to old payload')
            result = subprocess.run(command, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(old.read_text(), 'local change to old payload')

    def test_case_ids_cannot_escape(self):
        registry = runner.load_registry()
        for value in ('', '/tmp/escape', '../escape', 'a/b', 'a\\b', 'a\n'):
            with self.subTest(value=value):
                changed = copy.deepcopy(registry)
                changed['cases'][0]['id'] = value
                with patch.object(Path, 'read_text', return_value=json.dumps(changed)):
                    with self.assertRaises(ValueError):
                        runner.load_registry()

    def test_registry_rejects_unsafe_assertions_and_mutations(self):
        registry = runner.load_registry()
        for value in ('/tmp/secret', '../secret'):
            for key in ('state_assertions', 'permitted_fixture_mutations'):
                changed = copy.deepcopy(registry)
                changed['cases'][0][key] = ([{'path': value, 'operator': 'path-contains'}]
                                           if key == 'state_assertions' else [value])
                with self.subTest(value=value, key=key), patch.object(Path, 'read_text', return_value=json.dumps(changed)):
                    with self.assertRaises(ValueError):
                        runner.load_registry()

    def test_registration_lock_prevents_overlapping_writes(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            (project / '.agents/skills').mkdir(parents=True)
            (project / '.agents-ecosystem-registration.lock').mkdir()
            result = subprocess.run(['bash', str(ROOT / 'scripts/register-skills.sh'),
                                     '--project-root', str(project)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((project / '.cursor').exists())
            self.assertEqual(list((project / '.agents/skills').iterdir()), [])

    def test_assertions_cannot_read_external_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fixture = root / 'fixture'
            fixture.mkdir()
            sentinel = root / 'secret'
            sentinel.write_text('private sentinel')
            (fixture / 'link').symlink_to(root, target_is_directory=True)
            for value in (str(sentinel), '../secret', 'link/secret'):
                case = {'state_assertions': [{'operator': 'path-contains', 'path': value}]}
                with self.subTest(value=value), self.assertRaises(ValueError):
                    runner.capture_state_content(case, fixture)

    def test_input_symlink_ancestor_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'outside').mkdir()
            (root / 'outside/prompt').write_text('private sentinel')
            (root / 'link').symlink_to(root / 'outside', target_is_directory=True)
            with self.assertRaises(ValueError):
                runner.file_record(root / 'link/prompt', 'link/prompt')

    def test_registry_symlink_is_rejected_before_read(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'registry'
            path.symlink_to(ROOT / 'tests/agent-evals/cases.json')
            with patch.object(runner, 'REGISTRY_PATH', path), patch.object(Path, 'read_text') as read:
                with self.assertRaises(ValueError):
                    runner.load_registry()
                read.assert_not_called()

    def test_private_output_rejects_shared_parent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            root.chmod(0o777)
            with self.assertRaises(ValueError):
                runner.normalized_output_root(str(root / 'evidence'))
            root.chmod(0o700)

    def test_protected_state_records_never_retire(self):
        for version in (1, 2):
            for namespace in ('project', 'rules', 'templates'):
                with self.subTest(version=version, namespace=namespace), tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    source = root / 'source'
                    target = root / 'target'
                    source.mkdir()
                    (target / namespace).mkdir(parents=True)
                    owned = target / namespace / 'context.md'
                    owned.write_bytes(b'keep project context')
                    owned.chmod(0o644)
                    digest = hashlib.sha256(owned.read_bytes()).hexdigest()
                    relative = namespace + '/context.md'
                    state = target / f'.agents-ecosystem-managed-state-v{version}'
                    if version == 2:
                        state.write_text(f'agents-ecosystem-managed-state-v2\n{digest}\t644\t{relative}\n')
                    else:
                        state.write_bytes(('agents-ecosystem-managed-state-v1\0' + digest + '\0' + '644\0' + relative + '\0').encode())
                    state.chmod(0o644)
                    for mode in (['--check'], []):
                        result = subprocess.run(['bash', str(ROOT / 'scripts/sync-managed-tree.sh'), *mode,
                                                 '--exclude-top-level', 'templates', str(source), str(target)], capture_output=True)
                        self.assertNotEqual(result.returncode, 0, result.stdout)
                        self.assertEqual(owned.read_bytes(), b'keep project context')


if __name__ == '__main__':
    unittest.main()
