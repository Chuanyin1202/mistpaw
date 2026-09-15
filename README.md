# Mistpaw／霧爪

A playable single-level Godot ARPG experiment: keyboard combat, combo attacks,
double jumps, dodges, grouped enemies, loot, boss phases and HD-2D-inspired scenery.
The source code is MIT-licensed; bundled media has separate terms.

**授權：[程式碼 MIT](LICENSE) · [素材授權與來源](ASSET_LICENSES.md) · [參與方式](CONTRIBUTING.md)**

ARPG MVP 實驗專案，青霧林單關的完整可玩流程已完成，本階段收尾，不再擴充玩法或追逐概念圖品質。Godot 4.7.2／GDScript，以桌面高速動作刷寶為主，Web 提供試玩。


- 完整單關：群怪、三段普攻、重劈、旋斬、閃躲、二段跳、三種法寶、掉落與收取、妖王多階段／破防、死亡重試。
- 呈現：像素角色與 3D 森林／石橋／湖岸、場景及戰鬥光影、聲音、鍵盤與手機觸控 HUD。
- 本輪保留：路面朝向與樹影修正、新石板素材／薄石板幾何、遠景、水波與桌面抗鋸齒；降低過強補光與霧氣，加強揚塵及接地陰影。

[版本說明與驗證](docs/release-notes.md) · [完整含聲音展示](docs/mistpaw-final-gameplay.mp4) · [動作展示](docs/mistpaw-action-demo.mp4)。影片屬於先前驗收版，不代表本地最新光影。

## 啟動

在 Finder 雙擊 [scripts/play.command](scripts/play.command)，或終端機執行：

```sh
git clone https://github.com/Chuanyin1202/mistpaw.git
cd mistpaw
godot --headless --editor --import --quit
godot --path .
```

需要編輯時使用 `godot --path . --editor`，或在 Godot 匯入 `project.godot` 後按 F5。首次啟動會匯入／預熱素材。遊戲是原生視窗，無需網頁伺服器、不使用 5173／5174。

## 操作

| 動作 | 按鍵 |
|---|---|
| 移動／面向 | WASD／方向鍵，停止後保留面向 |
| 普攻 | J，按住連段；沒有敵人也可出劍 |
| 重劈／旋斬 | K／I，冷卻2.8／3.4秒 |
| 閃躲 | L，0.18秒突進、1.1秒冷卻 |
| 二段跳 | Space，空中再按一次 |
| 跑步 | 同方向在0.16秒內雙按，第二下按住；不再觸發後跳 |
| 法寶 | 1／2／3，取得後切換 |
| 提前迎戰 | F |
| 選單／靜音／重試 | Esc／M／R；結算亦可Enter |

右側圓形技能區顯示動作、鍵位與冷卻，按鍵與按鈕使用相同動作入口。桌面預設純鍵盤手動；Esc保留自動普攻輔助。滑鼠位置不影響戰鬥方向。手機支援橫向搖桿、多點觸控與安全區佈局；請使用正式 HTTPS 網址測試。

前三區各有三段遭遇：第一段取得法寶，後續改變站位與進場方向；戰間有 4 秒準備，可用 F 提前迎戰，掉落法寶需先收取。三戰完成後才觸發下一區遭遇，路面仍可自由往返。最後挑戰妖王，收齊四件法寶完成試煉。首次進入新區回復 20 點生命；生命歸零顯示倒下和重試。結算顯示用時、擊退數與承受傷害。

首次遊玩目標為 3–5 分鐘，尚待真人首玩量測；自動操作的通關時間不能當作真人遊玩時間。

## 驗證與複用

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/retry.gd
godot --headless --path . --script tests/atmosphere.gd
godot --headless --path . --script tests/flagstone_paving.gd
godot --path . --script tests/route.gd
godot --path . --script tests/quality_benchmark.gd
```

場景對照、路線與效能測試的輸出放在忽略追蹤的 `build/verification/`，不作歷史文件保存。

可供下一個專案參考的部分：動作輸入與連段、命中反馈、敵人預告、掉寶光柱與收取、音效分層、觸控控制，以及 Godot 場景材質。這些仍是遊戲內模組，尚非可直接安裝的通用框架；實際需要時再抽取。

素材來源與雜湊在 `assets/provenance.json`，製作資料在 `assets/source`。遊戲執行不需要音訊或生圖 API 金鑰。`../onepaw` 保持獨立。

未列為本 MVP 完成條件：商業級美術、概念圖完全還原、多關卡、背包養成、手把、多人、原生 Android／iOS，以及 Windows 實機驗證。Web 與桌面渲染能力不同，不能宣稱完全同畫質。

## Web 試玩

```sh
./web/export.sh
python3 web/serve.py --root build/web --port 8095
```

開啟 http://localhost:8095/。需要本機 Godot 4.7.2 與相同版本的 Web 單執行緒匯出模板，放在 `build/toolchain/`；匯出腳本會一起複製啟動 Logo。

桌面畫面以 1280×720 置中，較大視窗不放大，較小視窗等比例縮小。觸控手機的橫向畫布填滿瀏覽器可用區域，維持 720 渲染高度並延伸水平視野，不拉伸場景；直向提供完整載入頁，遊戲中轉直向會暫停並提示橫放。使用內附 Noto Sans TC Regular，中文字不依賴作業系統字型。Logo 為 `web/mistpaw-logo.png`，字型授權見 `assets/fonts/OFL.txt`。

Web 預設精緻，但不等同桌面 Forward+：沒有體積霧、SSR 與景深模糊。使用相容渲染專用光照／湖水色彩校正；桌面原有設定保留。精緻與均衡在 Web 的效果相近，清晰會減少環境裝飾。

手機橫向試玩已加入左側搖桿持續推動加速與右側多指動作控制，手指可從普攻滑向閃躲／跳躍；放手、觸控取消、暫停及失焦會清除觸控狀態。39 項合成觸控輸入檢查通過（含法寶點選、持續推桿加速與帶正負號的觸控編號）。

手機必須使用 HTTPS；區網 HTTP 不符合引擎的 secure-context 啟動條件。可用 `cloudflared tunnel --url http://127.0.0.1:8095 --no-autoupdate` 建立暫時試玩網址。此暫時網址依賴本機伺服器與 Tunnel 程序；正式試玩請用 https://mistpaw.eighti.app/ 。Safari「分享 → 加入主畫面」後以 Web App 開啟可移除網址列；桌面保留 16:9 原尺寸；手機橫向透過延伸視野使用可用空間。

手機快跑：搖桿離開中心緩衝區（22%）並維持方向 0.35 秒後自動進入完整 7.2 單位／秒跑速，外圈顯示蓄速與快跑狀態；中心附近微動不會加速，反向、放鬆、取消觸控及暫停會解除。上下與斜向移動也支援加速。移除獨立快跑按鈕與手機雙推觸發，鍵盤雙按保持原樣。




OG 採用開場 Logo 與背景，1200×630 分享圖為 `web/mistpaw-og.png`；排版來源 `web/og-card.html`。OG、Twitter large image 與 canonical 都指向正式網域。正式服務不啟用診斷接收；本機追查時須用伺服器 `--diagnostics` 搭配網址 `?touch_probe=1`。
