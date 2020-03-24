import nigui
import strformat
import strutils
import src/wav

var wavFilePath: string

# ====================================================================
# NiGui の始まり
# @see https://github.com/trustable-code/NiGui/
# ====================================================================
app.init()


# ====================================================================
# Window情報の定義
# ====================================================================

var window = newWindow("無音☆De☆カッター！")
var mainContainer = newLayoutContainer(Layout_Vertical)
window.add(mainContainer)

var buttons = newLayoutContainer(Layout_Horizontal)
mainContainer.add(buttons)

var thresholdArea = newLayoutContainer(Layout_Horizontal)
mainContainer.add(thresholdArea)

var silenceTimeArea = newLayoutContainer(Layout_Horizontal)
mainContainer.add(silenceTimeArea)


# ====================================================================
# エレメント
# ====================================================================

# wavファイル参照ダイアログボタンの定義
var openSelectWavFileDialogButton = newButton("ファイルの参照")
buttons.add(openSelectWavFileDialogButton)

# 分割後のwavファイル書き出し先フォルダ選択ボタン
var oepnSelectSaveWavFolderDialogButton = newButton("保存先フォルダーの選択")
buttons.add(oepnSelectSaveWavFolderDialogButton)

# 無音しきい値入力エリア
var labelThresholdArea = newLabel("無音と判別するしきい値（0～1）")
var textBoxThresholdArea = newTextBox("0.05")

# この値以上無音が続けばカットを行う秒数入力エリア
var labelsilenceTimeArea = newLabel("カットを行う無音秒数")
var textBoxsilenceTimeArea = newTextBox("2")

# --------------------------------
# wavファイル参照処理
# --------------------------------

# ボタンクリック時
openSelectWavFileDialogButton.onClick = proc(event: ClickEvent) =
    var dialog = newOpenFileDialog()
    dialog.title = "wavファイルを参照"
    dialog.multiple = false
    dialog.run()
    
    if dialog.files.len > 0:
        # wavファイルのパスを設定
        wavFilePath = dialog.files[0]

# --------------------------------
# 分割後のwavファイル書き出し処理
# --------------------------------

# ボタンクリック時
oepnSelectSaveWavFolderDialogButton.onClick = proc(event: ClickEvent) =
    if wavFilePath == "":
        window.alert("まずはwavファイルを選択してください")
        return

    # 各TextBoxの値を取得
    let thresholdStr = textBoxThresholdArea.text
    let silenceTimeStr = textBoxsilenceTimeArea.text

    let threshold = parseFloat(thresholdStr)
    let silenceTime = parseInt(silenceTimeStr)

    if threshold < 0.0 or 1.0 < threshold:
        window.alert("しきい値は0～1の間で入力をお願いしますわ")
        return

    if silenceTime < 0:
        window.alert("カットするタイミングは1秒以上で指定してくださいな")
        return

    var dialog = SelectDirectoryDialog()
    dialog.title = "分割したWavの保存先フォルダーの選択"
    dialog.run()
    if dialog.selectedDirectory != "":
        # 出力先フォルダーが選択されたら
        if wav.isWav(wavFilePath) == false:
            window.alert("このファイルはwavファイルではないっぽいです")
            return

        # wavの取得
        let wave = wav.readWave(wavFilePath)

        # 無音でカット
        let slices = wav.divideBySilence(wave, threshold, silenceTime)

        # 書き出し
        var cnt = 0
        for i in slices:
            wav.writeWave(fmt"{dialog.selectedDirectory}\out{cnt}.wav", i)

            cnt += 1
        
        window.alert("書き出しました")

# --------------------------------
# 無音と判別するしきい値入力場
# --------------------------------
thresholdArea.add(labelThresholdArea)
thresholdArea.add(textBoxThresholdArea)

# --------------------------------
# この値以上無音が続けばカットを行う秒数
# --------------------------------
silenceTimeArea.add(labelsilenceTimeArea)
silenceTimeArea.add(textBoxsilenceTimeArea)


# ====================================================================
# NiGui の終わり
# ====================================================================
window.show()
app.run()