#!/usr/bin/env python3
"""
update_backlog.py
capture_screenshots.js の結果を読んで tasks.backlog.yaml を更新する
"""

import json
import os
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKLOG_PATH = os.path.join(PROJECT_ROOT, 'docs', 'tasks.backlog.yaml')
RESULTS_PATH = os.path.join(PROJECT_ROOT, 'scripts', '.screenshot_results.json')

# スクリーンショットID → タスクIDのマッピング
SCREEN_TO_TASK = {
    'S-01':        'task-017',
    'S-02':        'task-003',
    'S-03':        'task-004',
    'S-03-loaded': 'task-012',
    'S-03-en':     'task-016',
    'S-04':        'task-007',
    'S-04-share':  'task-014',
    'S-05':        'task-008',
    'S-06':        'task-018',
}


def load_results():
    if not os.path.exists(RESULTS_PATH):
        print(f'❌ 結果ファイルが見つかりません: {RESULTS_PATH}')
        sys.exit(1)
    with open(RESULTS_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)


def parse_tasks(lines):
    """
    YAMLを行単位で解析してタスクブロックの開始/終了インデックスを返す
    返り値: { task_id: (start_line, end_line) }
    """
    tasks = {}
    current_id = None
    start = None

    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('- id:'):
            if current_id and start is not None:
                tasks[current_id] = (start, i)
            current_id = stripped.split(':', 1)[1].strip()
            start = i

    if current_id and start is not None:
        tasks[current_id] = (start, len(lines))

    return tasks


def ensure_screenshot_fields(lines):
    """全タスクに screenshot_path: null がなければ追加する"""
    result = []
    i = 0
    while i < len(lines):
        result.append(lines[i])
        stripped = lines[i].strip()
        if stripped.startswith('sns_hint:'):
            # 次の行が screenshot_path でなければ追加
            next_stripped = lines[i + 1].strip() if i + 1 < len(lines) else ''
            if not next_stripped.startswith('screenshot_path:'):
                result.append('    screenshot_path: null\n')
        i += 1
    return result


def update_screenshot_path(lines, task_id, path):
    """指定タスクの screenshot_path を更新する"""
    tasks = parse_tasks(lines)
    if task_id not in tasks:
        print(f'  ⚠️  {task_id} が見つかりません')
        return lines

    start, end = tasks[task_id]
    path_value = f'"{path}"' if path else 'null'

    for i in range(start, end):
        if lines[i].strip().startswith('screenshot_path:'):
            lines[i] = f'    screenshot_path: {path_value}\n'
            return lines

    print(f'  ⚠️  {task_id} に screenshot_path フィールドが見つかりません')
    return lines


def main():
    results = load_results()
    date = results['date']
    screenshots = results['screenshots']

    print(f'\n📝 tasks.backlog.yaml を更新中（{date}）\n')

    with open(BACKLOG_PATH, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 全タスクに screenshot_path フィールドを確保
    lines = ensure_screenshot_fields(lines)

    # 撮影結果を反映
    updated = set()
    for item in screenshots:
        screen_id = item['id']
        path = item['path']
        task_id = SCREEN_TO_TASK.get(screen_id)

        if not task_id or not path or task_id in updated:
            continue

        lines = update_screenshot_path(lines, task_id, path)
        updated.add(task_id)
        print(f'  ✅ {task_id} → {path}')

    with open(BACKLOG_PATH, 'w', encoding='utf-8') as f:
        f.writelines(lines)

    print(f'\n✅ tasks.backlog.yaml 更新完了')


if __name__ == '__main__':
    main()
