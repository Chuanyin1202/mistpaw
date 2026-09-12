# 步態與技能徽章製作記錄

側面步態：cat-walk-contact.png，2×2 四個不同接觸／交錯姿勢。参考旧 cat-walk.png 与 walk-contact-anchor.png；要求近腿／遠腿明暗差異、承重腿經過髖下、低抬腳、不跑跳。生成原圖 exec-d87dff14-ee96-4e45-8311-0dcb9a0de5de.png。sprite-forge preserve、shared X、全幀比例0.90、192格、feet對位，嚴格QC無裁切／碰邊；0.94碰邊試作未採用。來源與詳細QC見walk-contact-final/pipeline-meta.json。遊戲統一上移6px對齊接地，無逐幀縮放或碰撞體浮動。承重腳接觸至交錯約32px，側面每格位移32×0.022；全循環2.816世界單位。四格跑步、前後走路沿用既有版本。仍為離散像素姿勢，不宣稱骨架IK鎖腳。

技能圖集：action-medallions.png，六個青玉／古銅圓章，前五為普攻劍、重劈碎石、旋斬三刃、閃躲疾風、二段跳雲紋，第六空章備用。原生成 exec-f775d3e4-0c27-4b92-a4c9-1de4c32f1da7.png，修訂 exec-a4e0443f-bfe4-46bd-bd47-67f656fe1690.png。要求純透明外部、相同圓形邊框、2×3均勻排版；模型兩次仍輸出不透明背景，未聲稱取得真alpha素材。實作使用AtlasTexture指定區域及action_medallion.gdshader局部座標抗鋸齒圓形遮罩，原生畫面無方形底。非鍵色猜測去背，圖集原檔仍不透明。

普攻100px、其餘72px，名稱置於圓章下方，键位独立小牌，中心顯示冷卻／剩餘跳躍，外圈顯示冷卻進度。正常／按壓／動作中／冷卻／恢復短亮狀態共用同一元件；手機實機觸控尚未驗證。
