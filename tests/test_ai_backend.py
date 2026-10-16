import json
from pathlib import Path
import sys
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import ai_backend as ai


def profile(provider='codex', **kwargs):
    return dict(id='test', name='Test', provider=provider, **kwargs)


class Reply:
    def __init__(self, data): self.data = json.dumps(data).encode()
    def __enter__(self): return self
    def __exit__(self, *args): pass
    def read(self, limit): return self.data[:limit]


class AITests(unittest.TestCase):
    def test_preset_cli_commands_do_not_enable_shell_or_mcp(self):
        codex = ai.cli_command(ai.connection(profile(model='selected')))
        self.assertIn('--ignore-user-config', codex)
        self.assertIn('read-only', codex)
        self.assertIn('features.shell_tool=false', codex)
        self.assertEqual(codex[-3:], ['--model', 'selected', '-'])
        claude = ai.cli_command(ai.connection(profile('claude')))
        self.assertIn('--strict-mcp-config', claude)
        self.assertEqual(claude[claude.index('--tools')+1], '')

    def test_endpoints_refuse_insecure_remote_urls_and_embedded_secrets(self):
        for url in ('http://remote.example/v1', 'https://key@host/v1', 'https://host/v1?key=secret', 'file:///tmp/test', 'https://host/#key'):
            with self.assertRaises(ValueError): ai.connection(profile('compatible', baseUrl=url))
        self.assertEqual(ai.connection(profile('openai', baseUrl='http://evil'))['baseUrl'], 'https://api.openai.com/v1')
        ai.connection(profile('ollama', baseUrl='http://127.0.0.1:11434'))
        ai.connection(profile('ollama', baseUrl='http://[::1]:11434'))

    def test_key_scope_changes_with_endpoint_and_provider(self):
        a = ai.connection(profile('compatible', baseUrl='https://a/v1'))
        b = ai.connection(profile('compatible', baseUrl='https://b/v1'))
        self.assertNotEqual(ai.secret_args(a), ai.secret_args(b))
        self.assertNotIn('https://a', ' '.join(ai.secret_args(a)))

    def test_keys_go_via_stdin_and_keyring_failure_has_no_plaintext_fallback(self):
        p = ai.connection(profile('openai', model='chosen'))
        with patch.object(ai.shutil, 'which', return_value='/usr/bin/secret-tool'), patch.object(ai.subprocess, 'run') as run:
            run.return_value.returncode = 0
            run.return_value.stdout = ''
            ai.secret(p, 'store', 'secret-key')
            args, kwargs = run.call_args
            self.assertNotIn('secret-key', ' '.join(args[0]))
            self.assertEqual(kwargs['input'], 'secret-key')
            run.return_value.returncode = 1
            run.return_value.stderr = 'keyring locked; secret-key'
            with self.assertRaisesRegex(ValueError, 'keyring unavailable') as error: ai.secret(p, 'store', 'secret-key')
            self.assertNotIn('secret-key', str(error.exception))

    def test_missing_keyring_and_empty_secret(self):
        p = ai.connection(profile('openai', model='chosen'))
        with patch.object(ai.shutil, 'which', return_value=None):
            with self.assertRaisesRegex(ValueError, 'libsecret'): ai.secret(p, 'store', 'x')
            with self.assertRaisesRegex(ValueError, 'No API key'): ai.generate(p, 'test')

    def test_fixed_test_never_uses_request_notes(self):
        with patch.object(ai, 'generate', return_value='- Connection OK') as generate:
            result = ai.run(dict(operation='ai_test', connection=profile(), text='private notes'))
            self.assertNotIn('private notes', str(generate.call_args))
            self.assertIn('no notes', result['text'])
        with patch.object(ai, 'generate', return_value='debug logging, not an outline'):
            with self.assertRaisesRegex(ValueError, 'expected outline'): ai.run(dict(operation='ai_test', connection=profile()))

    def test_scope_changes_root_count_instructions(self):
        with patch.object(ai, 'generate', return_value='- result') as generate:
            ai.run(dict(operation='ai', connection=profile(), task='summarize', scope='roll', text='- a\n- b'))
            self.assertIn('one or more root items', generate.call_args.args[1])
            ai.run(dict(operation='ai', connection=profile(), task='summarize', scope='branch', text='- a'))
            self.assertIn('one root item,', generate.call_args.args[1])

    def test_unset_connection_unknown_operation_and_invalid_tasks_fail(self):
        for req in ({'operation':'ai'}, {'operation':'ai','connection':profile(),'task':'delete','text':'x'}):
            with self.assertRaises(ValueError): ai.run(req)

    def test_codex_and_claude_status_do_not_generate(self):
        with patch.object(ai.shutil, 'which', return_value='/bin/cli'), patch.object(ai, 'execute', return_value=(0, '', 'Logged in using ChatGPT')):
            result = ai.status(ai.connection(profile()))
            self.assertTrue(result['authenticated']); self.assertIn('ChatGPT', result['text'])
        with patch.object(ai.shutil, 'which', return_value='/bin/cli'), patch.object(ai, 'execute', return_value=(0, '{"loggedIn":false}', '')):
            self.assertFalse(ai.status(ai.connection(profile('claude')))['authenticated'])
        with patch.object(ai.shutil, 'which', return_value=None):
            self.assertIn('not installed', ai.status(ai.connection(profile()))['text'])

    def test_cli_failure_does_not_expose_stderr_secrets(self):
        with patch.object(ai, 'execute', return_value=(1,'','token=SECRET authentication failed')):
            with self.assertRaisesRegex(ValueError, 'Authentication failed') as error: ai.generate(ai.connection(profile()), 'x')
            self.assertNotIn('SECRET', str(error.exception))

    def test_openai_anthropic_response_formats_and_headers(self):
        cases = [('openai', {'output':[{'type':'message','content':[{'type':'output_text','text':'- OpenAI'}]}]}, '/responses', '- OpenAI'),
                 ('anthropic', {'content':[{'type':'text','text':'- Claude'}]}, '/messages', '- Claude')]
        for provider, data, suffix, expected in cases:
            with patch.object(ai.urllib.request, 'build_opener') as opener:
                opener.return_value.open.return_value = Reply(data)
                self.assertEqual(ai.generate(ai.connection(profile(provider, model='chosen')), 'prompt', 'SECRET'), expected)
                request = opener.return_value.open.call_args.args[0]
                self.assertTrue(request.full_url.endswith(suffix))
                body = json.loads(request.data)
                self.assertEqual(body['model'], 'chosen')
                if provider == 'openai': self.assertFalse(body['store'])
                self.assertNotIn('SECRET', request.data.decode())
                self.assertIn('SECRET', str(request.headers))

    def test_local_servers_and_redirects(self):
        seen = []
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args): pass
            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                seen.append((self.path, body, self.headers.get('Authorization')))
                if self.path.startswith('/redirect'):
                    self.send_response(302); self.send_header('Location', '/stolen'); self.end_headers(); return
                if self.path.startswith('/fail'):
                    self.send_response(401); self.end_headers(); self.wfile.write(b'SECRET private notes'); return
                self.send_response(200); self.end_headers()
                self.wfile.write(json.dumps({'message':{'content':'- local'}, 'choices':[{'message':{'content':'- compatible'}}]}).encode())
        server = HTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True); thread.start()
        base = 'http://127.0.0.1:' + str(server.server_port)
        try:
            with patch.object(ai.shutil, 'which', return_value=None):
                self.assertEqual(ai.generate(ai.connection(profile('ollama', baseUrl=base, model='local')), 'prompt'), '- local')
                self.assertFalse(seen[-1][1]['stream'])
                self.assertEqual(ai.generate(ai.connection(profile('compatible', baseUrl=base+'/v1', model='remote')), 'prompt', 'SECRET'), '- compatible')
                self.assertEqual(seen[-1][0], '/v1/chat/completions')
                self.assertEqual(seen[-1][2], 'Bearer SECRET')
                with self.assertRaisesRegex(ValueError, 'Authentication failed') as error:
                    ai.generate(ai.connection(profile('compatible', baseUrl=base+'/fail', model='x')), 'private notes', 'SECRET')
                self.assertNotIn('SECRET', str(error.exception))
                with self.assertRaisesRegex(ValueError, 'HTTP 302'):
                    ai.generate(ai.connection(profile('compatible', baseUrl=base+'/redirect', model='x')), 'x', 'SECRET')
                self.assertFalse(any(path == '/stolen' for path, _, _ in seen))
        finally:
            server.shutdown(); server.server_close(); thread.join()


if __name__ == '__main__': unittest.main()
