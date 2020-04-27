import nigui
import strformat
import strutils
import src/wav


# ====================================================================
# NiGui の始まり
# @see https://github.com/trustable-code/NiGui/
# ====================================================================
app.init()


# ====================================================================
# Window情報の定義
# ====================================================================

var window = newWindow("無音☆De☆カッター！")
var mainContainer = newContainer()
window.add(mainContainer)
window.width = 640.scaleToDpi
window.height = 355.scaleToDpi


# ====================================================================
# エレメント
# ====================================================================

# wavファイルのパスを
var wavFilePathTextBox = newTextBox("")
mainContainer.add(wavFilePathTextBox)
wavFilePathTextBox.x = 5
wavFilePathTextBox.y = 10
wavFilePathTextBox.width = 480
wavFilePathTextBox.height = 21
wavFilePathTextBox.editable = false

# wavファイル参照ダイアログボタンの定義
var openSelectWavFileDialogButton = newButton("ファイルの参照")
mainContainer.add(openSelectWavFileDialogButton)
openSelectWavFileDialogButton.x = 490
openSelectWavFileDialogButton.y = 8
openSelectWavFileDialogButton.width = 100
openSelectWavFileDialogButton.height = 25

# チャンネル数表示
var channelDescriptionLabel = newLabel("チャンネル数")
mainContainer.add(channelDescriptionLabel)
channelDescriptionLabel.x = 5
channelDescriptionLabel.y = 50
channelDescriptionLabel.width = 60
channelDescriptionLabel.height = 21

var channelValueTextBox = newTextBox("")
mainContainer.add(channelValueTextBox)
channelValueTextBox.x = 70
channelValueTextBox.y = 45
channelValueTextBox.width = 50
channelValueTextBox.height = 23
channelValueTextBox.editable = false

# サンプリング周波数
var samplingFrequencyDescriptionLabel = newLabel("サンプリング周波数")
mainContainer.add(samplingFrequencyDescriptionLabel)
samplingFrequencyDescriptionLabel.x = 180
samplingFrequencyDescriptionLabel.y = 50
samplingFrequencyDescriptionLabel.width = 90
samplingFrequencyDescriptionLabel.height = 21

var samplingFrequencyValueTextBox = newTextBox("")
mainContainer.add(samplingFrequencyValueTextBox)
samplingFrequencyValueTextBox.x = 280
samplingFrequencyValueTextBox.y = 45
samplingFrequencyValueTextBox.width = 100
samplingFrequencyValueTextBox.height = 23
samplingFrequencyValueTextBox.editable = false

# 量子化ビット数
var quantizationBitsDescriptionLabel = newLabel("量子化ビット数")
mainContainer.add(quantizationBitsDescriptionLabel)
quantizationBitsDescriptionLabel.x = 440
quantizationBitsDescriptionLabel.y = 50
quantizationBitsDescriptionLabel.width = 80
quantizationBitsDescriptionLabel.height = 21

var quantizationBitsValueTextBox = newTextBox("")
mainContainer.add(quantizationBitsValueTextBox)
quantizationBitsValueTextBox.x = 520
quantizationBitsValueTextBox.y = 45
quantizationBitsValueTextBox.width = 50
quantizationBitsValueTextBox.height = 23
quantizationBitsValueTextBox.editable = false

# 無音と判別する音量の大きさのしきい値
var thresholdVolumeDescriptionLabel = newLabel("無音と判別するしきい値（0～1）")
mainContainer.add(thresholdVolumeDescriptionLabel)
thresholdVolumeDescriptionLabel.x = 5
thresholdVolumeDescriptionLabel.y = 100
thresholdVolumeDescriptionLabel.width = 160
thresholdVolumeDescriptionLabel.height = 21

var thresholdVolumeValueTextBox = newTextBox("0.05")
mainContainer.add(thresholdVolumeValueTextBox)
thresholdVolumeValueTextBox.x = 170
thresholdVolumeValueTextBox.y = 95
thresholdVolumeValueTextBox.width = 120
thresholdVolumeValueTextBox.height = 23

# 無音がこの秒数続くとカットポジションと判別
var silenceTimeDescriptionLabel = newLabel("無音がこの秒数続くとカットポジションと判別")
mainContainer.add(silenceTimeDescriptionLabel)
silenceTimeDescriptionLabel.x = 5
silenceTimeDescriptionLabel.y = 130
silenceTimeDescriptionLabel.width = 210
silenceTimeDescriptionLabel.height = 21

var silenceTimeValueTextBox = newTextBox("2")
mainContainer.add(silenceTimeValueTextBox)
silenceTimeValueTextBox.x = 220
silenceTimeValueTextBox.y = 125
silenceTimeValueTextBox.width = 160
silenceTimeValueTextBox.height = 23

# 切り出したファイルが全て無音だった場合は出力しない
var noOutputAllSilenceCheckBox = newCheckbox("ファイルがすべて無音の場合はそのファイル出力しない")
mainContainer.add(noOutputAllSilenceCheckBox)
noOutputAllSilenceCheckBox.x = 5
noOutputAllSilenceCheckBox.y = 160
noOutputAllSilenceCheckBox.width = 265
noOutputAllSilenceCheckBox.height = 21

# 前後の無音を削除
var trimSilenceCheckBox = newCheckbox("切り出したファイルの前後の無音をカットする")
mainContainer.add(trimSilenceCheckBox)
trimSilenceCheckBox.x = 5
trimSilenceCheckBox.y = 180
trimSilenceCheckBox.width = 265
trimSilenceCheckBox.height = 21

# 出力先フォルダーパス
var outputFolderPathTextBox = newTextBox("")
mainContainer.add(outputFolderPathTextBox)
outputFolderPathTextBox.x = 5
outputFolderPathTextBox.y = 213
outputFolderPathTextBox.width = 480
outputFolderPathTextBox.height = 21
outputFolderPathTextBox.editable = false

# 出力先フォルダーを指定するボタン
var oepnSelectSaveWavFolderDialogButton = newButton("出力先フォルダーの選択")
mainContainer.add(oepnSelectSaveWavFolderDialogButton)
oepnSelectSaveWavFolderDialogButton.x = 490
oepnSelectSaveWavFolderDialogButton.y = 210
oepnSelectSaveWavFolderDialogButton.width = 130
oepnSelectSaveWavFolderDialogButton.height = 25

# 出力ボタン
var cuttingStartButton = newButton("無音でカット開始")
mainContainer.add(cuttingStartButton)
cuttingStartButton.x = 420
cuttingStartButton.y = 250
cuttingStartButton.width = 200
cuttingStartButton.height = 60


# ====================================================================
# イベント
# ==================================================================== 

# --------------------------------
# wavファイル参照処理
# --------------------------------

openSelectWavFileDialogButton.onClick = proc(event: ClickEvent) =
    var dialog = newOpenFileDialog()
    dialog.title = "wavファイルを参照"
    dialog.multiple = false
    dialog.run()
    
    if dialog.files.len > 0:
        # wavファイルかを確認
        if wav.isWav(dialog.files[0]) == false:
            window.alert("このファイルはwavファイルではないっぽいです")
            return

        # wavファイルのパスを設定
        wavFilePathTextBox.text = dialog.files[0]

        # wav情報を取得
        let wavData = wav.readWave(wavFilePathTextBox.text)
        channelValueTextBox.text = $wav.getChannel(wavData)
        samplingFrequencyValueTextBox.text = $wav.getSamplingFrequency(wavData)
        quantizationBitsValueTextBox.text = $wav.getQuantizationBits(wavData)


# --------------------------------
# 分割後のwavファイル書き出しフォルダーパス
# --------------------------------

oepnSelectSaveWavFolderDialogButton.onClick = proc(event: ClickEvent) =
    var dialog = SelectDirectoryDialog()
    dialog.title = "分割したWavの保存先フォルダーの選択"
    dialog.run()
    if dialog.selectedDirectory != "":
        # 出力先フォルダーが選択されたら
        outputFolderPathTextBox.text = dialog.selectedDirectory & "\\"


# --------------------------------
# 分割処理
# --------------------------------

cuttingStartButton.onClick = proc(event: ClickEvent) =
    # 出力先フォルダーパスが設定されているか
    if outputFolderPathTextBox.text == "":
        window.alert("出力先フォルダーパスが設定されていないです")
        return

    if wavFilePathTextBox.text == "":
        window.alert("wavファイルを選択してください")
        return
    
    # wavファイルかを確認
    if wav.isWav(wavFilePathTextBox.text) == false:
        window.alert("このファイルはwavファイルではないっぽいです")
        return

    # 各TextBoxの値を取得
    let thresholdStr = thresholdVolumeValueTextBox.text
    let silenceTimeStr = silenceTimeValueTextBox.text

    let threshold = parseFloat(thresholdStr)
    let silenceTime = parseInt(silenceTimeStr)

    if threshold < 0.0 or 1.0 < threshold:
        window.alert("しきい値は0～1の間で入力をお願いしますわ")
        return

    if silenceTime < 0:
        window.alert("カットするタイミングは1秒以上で指定してくださいな")
        return

    # 無音で切り出したファイルがすべて無音の場合は、そのファイルを出力しない
    let isIgnoreAllSilence = noOutputAllSilenceCheckBox.checked

    # 前後の無音をカットする
    let isTrimSilence = trimSilenceCheckBox.checked
    
    # wavの取得
    let wave = wav.readWave(wavFilePathTextBox.text)

    # 無音でカット
    let slices = wav.divideBySilence(wave, threshold, silenceTime)

    # 書き出し
    var cnt = 0
    for i in slices:
        var writeData = i

        # すべて無音の場合は書き出さない
        if isIgnoreAllSilence == true and wav.isAllSilence(writeData, threshold) == true:
            continue

        # 必要なら前後の無音をカットする
        if isTrimSilence == true:
            writeData = wav.trimSilence(writeData, threshold, silenceTime, 0.1, 0.0)

        wav.writeWave(fmt"{outputFolderPathTextBox.text}\out{cnt}.wav", writeData)

        cnt += 1
    
    window.alert("書き出しました")


# ====================================================================
# NiGui の終わり
# ====================================================================
window.show()
app.run()