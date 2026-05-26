---
description: ECC リポジトリの最新変更を pull し、現在管理対象のターゲットを再インストールする / Pull the latest ECC repo changes and reinstall the current managed targets.
disable-model-invocation: true
---

# Auto Update

ECC を upstream リポジトリから更新し、元の install-state リクエストを使って現在のコンテキストの managed install を再生成する。

## Usage

```bash
# Preview the update without mutating anything
ECC_ROOT="${CLAUDE_PLUGIN_ROOT:-$(node -e "var r=(()=>{var e=process.env.CLAUDE_PLUGIN_ROOT;if(e&&e.trim())return e.trim();var p=require('path'),f=require('fs'),h=require('os').homedir(),d=p.join(h,'.claude'),q=p.join('scripts','lib','utils.js');if(f.existsSync(p.join(d,q)))return d;for(var s of [['ecc'],['ecc@ecc'],['marketplace','ecc'],['everything-claude-code'],['everything-claude-code@everything-claude-code'],['marketplace','everything-claude-code']]){var l=p.join(d,'plugins',...s);if(f.existsSync(p.join(l,q)))return l}try{for(var g of ['ecc','everything-claude-code']){var b=p.join(d,'plugins','cache',g);for(var o of f.readdirSync(b,{withFileTypes:true})){if(!o.isDirectory())continue;for(var v of f.readdirSync(p.join(b,o.name),{withFileTypes:true})){if(!v.isDirectory())continue;var c=p.join(b,o.name,v.name);if(f.existsSync(p.join(c,q)))return c}}}}catch(x){}return d})();console.log(r)")}"
node "$ECC_ROOT/scripts/auto-update.js" --dry-run

# Update only Cursor-managed files in the current project
node "$ECC_ROOT/scripts/auto-update.js" --target cursor

# Override the ECC repo root explicitly
node "$ECC_ROOT/scripts/auto-update.js" --repo-root /path/to/everything-claude-code
```

## 注意事項

- このコマンドは記録された install-state リクエストを使用し、最新のリポジトリ変更を pull した後に `install-apply.js` を再実行する。
- 再インストールは意図的である：これは `repair.js` が古い操作のみから安全に再構成できない、upstream のリネームや削除に対応する。
- 何かを変更する前に再構成された再インストール計画を確認したい場合は、まず `--dry-run` を使用すること。
