"""firestore.rules の世帯グループ(household_groups)の更新ルールを、Firebase Rules の検証 API で検査する。配備はしない。

使い方:
  python tools/test_household_rules.py okane-bea50
要件: gcloud にログイン済み（`gcloud auth print-access-token` が使える）こと。Java やエミュレータは不要。
"""
import json
import pathlib
import subprocess
import sys
import urllib.error
import urllib.request

project = sys.argv[1] if len(sys.argv) > 1 else 'okane-bea50'
rules = (pathlib.Path(__file__).parent.parent / 'firestore.rules').read_text(encoding='utf-8')
token = subprocess.run('gcloud auth print-access-token', shell=True, capture_output=True, text=True).stdout.strip()

DOC = '/databases/(default)/documents'
GROUP = f'{DOC}/household_groups/g1'

before = {
    'members': ['u1', 'u2'],
    'memberNicknames': {'u1': 'たろう', 'u2': 'はなこ'},
    'memberContributions': {'u1': 1000, 'u2': 2000},
    'totalSavings': 3000,
}


# isMember() が get() でグループ文書を読むため、既存の文書をモックとして渡す。
MOCKS = [{
    'function': 'get',
    'args': [{'exactValue': '/databases/%28default%29/documents/household_groups/g1'}],
    'result': {'value': {'data': before}},
}]


def sub_write(name, uid, expect):
    return {
        'name': name,
        'expectation': expect,
        'request': {
            'method': 'create', 'path': f'{GROUP}/family_missions/m1',
            'auth': {'uid': uid, 'token': {}},
            'resource': {'data': {'title': 'みんなで貯金'}},
        },
        'functionMocks': MOCKS,
    }


def update(name, uid, after, expect):
    return {
        'name': name,
        'expectation': expect,
        'request': {
            'method': 'update', 'path': GROUP,
            'auth': {'uid': uid, 'token': {}},
            'resource': {'data': after},
        },
        'resource': {'data': before},
        'functionMocks': MOCKS,
    }


cases = [
    # --- 今回追加: 自分だけが抜ける ---
    update('メンバー本人の脱退（members/ニックネーム/貢献額から自分だけ削除）は許可', 'u1',
           {'members': ['u2'], 'memberNicknames': {'u2': 'はなこ'},
            'memberContributions': {'u2': 2000}, 'totalSavings': 3000}, 'ALLOW'),
    update('他人(u2)をメンバーから外すのは拒否', 'u1',
           {'members': ['u1'], 'memberNicknames': {'u1': 'たろう'},
            'memberContributions': {'u1': 1000}, 'totalSavings': 3000}, 'DENY'),
    update('脱退と同時に totalSavings を書き換えるのは拒否', 'u1',
           {'members': ['u2'], 'memberNicknames': {'u2': 'はなこ'},
            'memberContributions': {'u2': 2000}, 'totalSavings': 0}, 'DENY'),
    update('非メンバーが他人を外すのは拒否', 'u9',
           {'members': ['u2'], 'memberNicknames': {'u2': 'はなこ'},
            'memberContributions': {'u2': 2000}, 'totalSavings': 3000}, 'DENY'),
    update('メンバー全員を空にするのは(他人も外すので)拒否', 'u1',
           {'members': [], 'memberNicknames': {}, 'memberContributions': {},
            'totalSavings': 3000}, 'DENY'),
    # --- 既存の挙動が変わっていないこと ---
    update('メンバーによる貯蓄の加算は許可', 'u1',
           {**before, 'totalSavings': 3500,
            'memberContributions': {'u1': 1500, 'u2': 2000}}, 'ALLOW'),
    update('非メンバーの自己参加（自分だけ追加）は許可', 'u9',
           {**before, 'members': ['u1', 'u2', 'u9'],
            'memberNicknames': {**before['memberNicknames'], 'u9': 'じろう'}}, 'ALLOW'),
    update('非メンバーが totalSavings を書き換えるのは拒否', 'u9',
           {**before, 'totalSavings': 0}, 'DENY'),
    # --- サブコレクション(family_missions 等)はメンバーのみ ---
    sub_write('メンバーはサブコレクションに書ける', 'u1', 'ALLOW'),
    sub_write('非メンバーはサブコレクションに書けない', 'u9', 'DENY'),
    # --- 抜け穴の回帰: メンバーでも他人を外せない/合計を書き換えられない ---
    update('メンバーが totalSavings だけを任意の値にするのは許可（貯蓄加算と区別できないため）', 'u1',
           {**before, 'totalSavings': 0}, 'ALLOW'),
]

names = [c.pop('name') for c in cases]
body = {'source': {'files': [{'name': 'firestore.rules', 'content': rules}]},
        'testSuite': {'testCases': cases}}
req = urllib.request.Request(
    f'https://firebaserules.googleapis.com/v1/projects/{project}:test',
    data=json.dumps(body).encode('utf-8'),
    headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json',
             'x-goog-user-project': project},
    method='POST')
try:
    res = json.load(urllib.request.urlopen(req))
except urllib.error.HTTPError as e:
    print('HTTP', e.code, e.read().decode('utf-8')[:1500])
    sys.exit(2)

issues = res.get('issues', [])
for i in issues:
    print('ルールの問題:', i)
results = res.get('testResults', [])
fail = 0
for n, r in zip(names, results):
    ok = r.get('state') == 'SUCCESS'
    fail += 0 if ok else 1
    print(('OK  ' if ok else 'NG  ') + n, '' if ok else json.dumps(r, ensure_ascii=False)[:300])
print(f'{len(results) - fail}/{len(results)} 件が期待どおり')
sys.exit(1 if fail or issues else 0)
