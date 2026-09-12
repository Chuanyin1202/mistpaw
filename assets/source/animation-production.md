# 本輪動畫來源與採用

所有新圖片由內建 image_gen 生成。sprite-forge 負責確定性 chroma、切幀、共同尺度及腳底對位；沒有逐幀縮放或放寬 QC 門檻。

| 採用 | raw／QC | 跨幀 body CV | anchor Y std |
|---|---|---|---|
| cat-cut-eight 前四格 | cat-attack-a | 0.02705 | 0.01011 |
| cat-cut-eight 後四格 | cat-attack-b | 0.03443 | 0.01818 |
| cat-jump | cat-jump-v3 | 0.01972 | 0.02278 |
| cat-spin | cat-spin | 0.02043 | 0.00239 |
| rat-run／weasel-run | 各目錄 pipeline-meta.json | 通過 ≤0.08 | 通過 ≤0.05 |

攻擊以两个 2×2 raw sheet 分別生成、QC 通過後直接拼成 2×4 atlas。A：備架、抬劍、頭頂頂點、向前加速；B：下劈接觸、低位跟隨、收劍、回架。以上是製作規格摘要；原始完整 A／B 提示未寫入檔案，不把此摘要冒充原提示。兩份生成原圖與確定性處理 metadata 已保存，可重新切幀。

跳躍／旋斬／老鼠／風鼬的提示檔分別為 jump-prompt.txt、spin-prompt.txt、rat-run-prompt.txt、weasel-run-prompt.txt。跳躍兩次位置修正記於 jump-repair-prompt.txt、jump-repair-prompt3.txt。第一／二版跳躍與九格揮劍未通過腳底偏移 QC，未投入運行。

旋斬光弧獨立於角色生成，使用黑底 additive 圖；原始版本碰邊，修正後採用。提示見 spin-fx-prompt.txt、spin-fx-repair-prompt.txt。不使用程序光環作最終版本。

最終素材位置與 SHA256 見 ../provenance.json。

## 獨立重劈與妖王出爪

重劈由 heavy-windup-v3 與 heavy-release 各四格直接拼成 cat-heavy-eight.png，不逐格縮放。兩組身體尺度 CV 分別 0.02649／0.01736，對 walk 的 mean 漂移 +4.08%／+0.81%；無越格、空格或裁切。windup 初稿尺度漂移超過 10%、v2 過小，均未採用。

妖王 boss-claw 的 CV 0.02634、腳底 anchor 標準差 0.00464，無越格／空格／clamp。原稿出爪跨格，修正後才採用。舊素材沒有原始 QC，參考從舊 192 格抽出的 112px 高角色重建；新格高度 108–117px，這是輸出尺寸比較，不能冒充原始 profile 比對。

contact-spark.png 使用黑底加色合成，外框最大色階 1/255，保有黑邊安全區；不是透明角色素材。提示詞、原圖及處理數據保留在 source 子目錄，最終檔案 SHA-256 見 assets/provenance.json。

## 縱向移動、跑步與後跳

後續跑步更新：正式採用 `run-dense-aligned` 六格（`cat-run-six.png`）。body_scale_mean 0.433218、CV 0.015241、anchor_y_std 0.035280，無碰邊／夾位；相較原四格尺度均值 0.418187 增加 3.59%，低於 10% 上限。第一稿 `run-dense` 的 anchor_y_std 0.052111 超過 0.05，未採用；修圖後以明確 strict thresholds 重跑。全格使用共同比例與水平錨，沒有逐格縮放。完整提示見 run-dense-prompt.txt，原生六格播放測試與 run-trial.png 已驗證。

四組 2×2 圖集採同一角色參考，feet/shared-scale/preserve/shared-X 處理；未逐幀縮放。toward/away 停步保留縱向姿態，攻擊、閃避與後跳切換到對應圖集。

| 素材 | body CV | anchor Y std | 對 walk 尺度漂移 |
|---|---|---|---|
| walk-toward | 0.00719 | 0.01204 | +2.08% |
| walk-away | 0.00577 | 0.01943 | +2.96% |
| run-four | 0.01297 | 0.00114 | −4.20% |
| backstep-four | 0.01906 | 0.02077 | −1.33% |

六格跑步初稿腳底 std 0.05934 超過 0.05，未採用；重新生成四格完整步態，未放寬門檻。接受稿、完整提示及 pipeline-meta 均保存在對應 source 目錄。原生截圖：docs/movement-away.png、movement-toward.png、run-trial.png、backstep-trial.png。

## 三段普攻：橫斬與低位突刺

第一段沿用 cat-cut-eight 下劈；第二段 cat-combo-sweep 由 combo-sweep-a/b 組成；第三段 cat-combo-thrust 由 combo-thrust-low-a/b 組成。各動作兩組四格、合併為 384×768 八格圖集，固定 192 格，未逐幀縮放。皆由內建生圖工具生成，沿用 master 與 attack-anchor-four；提示及確定性 QC 保存在上述 source 目錄。

| 接受稿 | body CV | anchor Y std | 對 walk 平均尺度漂移 |
|---|---|---|---|
| sweep-a | 0.01105 | 0.02723 | +0.21% |
| sweep-b | 0.01498 | 0.02585 | +0.02% |
| thrust-low-a | 0.02177 | 0.03717 | −0.40% |
| thrust-low-b | 0.05124 | 0.01504 | −2.69% |

無空格、碰格邊或 paste clamp。突刺初稿 combo-thrust-a/b 數字 QC 通過，但實際姿勢出劍過高且在接觸前伸到底，未採用；低位接觸稿先確定，再重生相符蓄勢。初稿透明輸出曾以 pre-keyed 重跑，沒有強行替換 alpha。

thrust-flash.png 為獨立黑底加色特效，shader 取中央光束區並配合低位刺擊傾斜；橫斬重用既有 slash-down 光弧素材，旋轉取樣並調整橫向比例。實際畫面見 docs/combo-1-contact.png 至 combo-3-contact.png。

## 法寶與受擊／倒下素材

wave-blade、chain-lightning、vital-wisp 是獨立黑底加色圖，原圖直接保留，禁止以角色 chroma 管線處理發光邊緣。引擎加色材質關閉 fog，避免零亮度區被場景霧染成矩形。wave-swish、lightning-crack、vital-return 音訊來自 build-sounds.py，44.1 kHz 單聲道 PCM，峰值分別 0.1423／0.1637／0.1844。

角色／怪物均為 2×2 四格，每格 192，feet/shared-scale/preserve/shared-X；無逐幀缩放。cat-hurt 與 weasel-fall 生成結果本身有 alpha，使用 pre-keyed，其他角色用洋紅去背。所有接受稿無空格、碰邊或 paste clamp，原圖與 pipeline-meta 保留。

| 素材 | body CV | anchor Y std |
|---|---|---|
| cat-hurt | 0.01607 | 0.00081 |
| cat-fall | 0.12415 | 0.07745 |
| rat-bite | 0.01293 | 0.03672 |
| weasel-pounce | 0.02784 | 0.05866 |
| toad-spit | 0.02340 | 0.00070 |
| rat-fall | 0.05273 | 0.02701 |
| weasel-fall | 0.07325 | 0.03486 |
| toad-fall | 0.03171 | 0.01625 |
| elite-fall | 0.06054 | 0.04830 |
| boss-fall | 0.06055 | 0.03803 |

cat-hurt 對 walk 尺度 +8.73%；rat-bite 對 rat-run +3.80%；weasel-pounce 對 weasel-run −3.43%。倒下改變輪廓面积、撲擊離地，所以不冒充通過站姿 CV／腳底 gate；依原始比例、無裁切、同頭身與實機落地位置判讀，未放寬站姿門檻。石蟾／精英的舊圖沒有原始 profile；從舊圖第一格抽 master、建立 anchor，不能宣稱做過原始 profile 驗證。

風鼬撲擊初稿跨格、妖王倒下初稿鹿角碰格邊，重生 compact 版本後才接入，沒有以裁切或逐幀縮小掩蓋。實際傷害時點仍由程式控制，圖片不包含劍光或投射物。


## 精英落爪與旋轉飛石

`elite-maul` / `stone-flight` 各四格 2×2 圖集。原始圖與去背結果保留於同名目錄；提示在上一層 `*-prompt.txt`，QC 詳見 `pipeline-meta.json`。精英以腳底對齊、共用尺度与 X 中心；飛石以中心對齊，不逐格放大。精英占高平均 0.4278、CV 0.00477；飛石平均 0.3456、CV 0.00674，皆無撞框或裁切。執行時依預告／接觸／收勢和彈道存活時間選幀。


## 妖王衝撞與躍擊

兩者用同一 boss-master 與 boss-attack-anchor 參考，各為 2×2 四格。衝撞圖經重生修正出格、跨動作縮小與棋盤格烘焙问题，最终 raw 使用洋紅清除；躍擊 raw 有真正 alpha，使用 pre-keyed 保留透明度。均用共用 X、腳底對齊与單一 preserve 比例，沒有逐幀縮放。

| 圖集 | body scale mean | CV | 腳底標準差 | 出格／裁切 |
|---|---:|---:|---:|---|
| 原落爪 | 0.4981 | 0.0263 | 0.0046 | 0 |
| 衝撞 | 0.4826 | 0.0192 | 0.0292 | 0 |
| 躍擊 | 0.5052 | 0.0355 | 0.0261 | 0 |

相對落爪的尺度漂移約 −3.1%／+1.4%。逐幀來源、QC 與完整修正提示保留在同名資料夾及 `*-prompt.txt`。
