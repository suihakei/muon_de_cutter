import streams
import math
import algorithm

# ====================================================================
# 前方宣言（Cで言うプロトタイプ宣言）
# ====================================================================

proc getDecibel(volume: float, fmtBitsPerSample: int = 16): float


# ====================================================================
# ■ waveの構造情報
# 参考： https://hwswsgps.hatenablog.com/entry/2018/08/19/172401
# ====================================================================
type WAV = object  
    # RIFFヘッダ                    
    headerId: string                    # RIFF形式に沿っていることを表す文字列
    headerSize: int32                   # 音データ + 36（RIFFのtypeパラメータ～データチャンクのsizeパラメータの総サイズ）
    headerType: string                  # そのファイルの識別子

    # フォーマットチャンク
    fmtId: string                       # フォーマットチャンクを表す文字列
    fmtSize: int32                      # フォーマットチャンクのサイズ（基本16）
    fmtFormat: int16                    # ファイルの形式。通常のWaveなら1
    fmtChannel: int16                   # 音声データのチャンネル数（1 or 2）
    fmtSamplesPerSec: int32             # サンプリング周波数
    fmtBytesPerSec: int32               # 一秒あたりのバイト数 = サンプリング周波数×量子化ビット数 × チャンネル数 / 8
    fmtBlockSize: int16                 # 1ブロックのサイズ = 量子化ビット数 / 8 × チャンネル数
    fmtBitsPerSample: int16             # 量子化ビット数

    # データチャンク
    dataId: string                      # データチャンクを表す文字列
    dataSize: int32                     # 実際に格納される音データのサイズ                    
    data: seq[float]                    # 実際の音データ


proc readWave*(filePath: string): WAV =
    ##
    ## wavファイルをメモリに読み込みます
    ##
    ## filePath string: wavファイルのパスを指定

    var wav: WAV
    var data: int16

    # ファイルをReadモードでOpen
    var fr = newFileStream(filePath, FileMode.fmRead)

    # Waveファイル情報を取得
    wav.headerId = fr.readStr(4)
    wav.headerSize = fr.readInt32()
    wav.headerType = fr.readStr(4)
    wav.fmtId = fr.readStr(4)
    wav.fmtSize = fr.readInt32()
    wav.fmtFormat = fr.readInt16()
    wav.fmtChannel = fr.readInt16()
    wav.fmtSamplesPerSec = fr.readInt32()
    wav.fmtBytesPerSec = fr.readInt32()
    wav.fmtBlockSize = fr.readInt16()
    wav.fmtBitsPerSample = fr.readInt16()
    wav.dataId = fr.readStr(4)
    wav.dataSize = fr.readInt32()

    # 音情報を取得する
    let dataLength = int32(int(wav.dataSize) / wav.fmtBlockSize)
    for i in 0..dataLength - 1:
        data = fr.readInt16()
        wav.data.add(data / 32767)
    
    fr.close()

    return wav


proc writeWave*(filePath: string, wav: WAV) =
    ##
    ## wavファイルをファイルに書き出します
    ##
    ## filePath string: wavファイルのパスを指定
    ## wav WAV: 書き出しWAV構造体を指定

    var data: int16
    let dataLength = int32(int(wav.dataSize) / wav.fmtBlockSize)

    # ファイルをWriteモードでOpen
    var fw = newFileStream(filePath, FileMode.fmWrite)

    # wavヘッダー書き込み
    fw.write(wav.headerId)
    fw.write(wav.headerSize)
    fw.write(wav.headerType)

    # wavフォーマット書き込み
    fw.write(wav.fmtId)
    fw.write(wav.fmtSize)
    fw.write(wav.fmtFormat)
    fw.write(wav.fmtChannel)
    fw.write(wav.fmtSamplesPerSec)
    fw.write(wav.fmtBytesPerSec)
    fw.write(wav.fmtBlockSize)
    fw.write(wav.fmtBitsPerSample)

    # wavデータ書き込み
    fw.write(wav.dataId)
    fw.write(wav.dataSize)

    # 音声データ書き込み
    for i in 0..dataLength - 1:
        if wav.data[i] > 1:             # クリッピング（メモリのオーバーフローを防ぐため）
            data = 32767
        elif wav.data[i] < -1:          # クリッピング（メモリのオーバーフローを防ぐため）
            data = -32767
        else:
            data = (int16)(wav.data[i] * 32767.0)

        fw.write(data)

    fw.close()


proc isWav*(filePath: string): bool =
    ##
    ## 与えられたファイルパスのファイルがwavファイル化を確認します
    ##
    ## filePath string: wavファイルまでのパス

    var wav: WAV

    # ファイルをReadモードでOpen
    var fr = newFileStream(filePath, FileMode.fmRead)

    # Waveファイル情報を取得
    wav.headerId = fr.readStr(4)
    if wav.headerId != "RIFF":
        return false

    wav.headerSize = fr.readInt32()
    wav.headerType = fr.readStr(4)
    if wav.headerType != "WAVE":
        return false

    wav.fmtId = fr.readStr(4)
    if wav.fmtId != "fmt ":
        return false
    
    return true


proc getChannel*(wav: WAV): int16 =
    ##
    ## チャンネル数を取得
    ##
    ## wav WAV: wavオブジェクトを指定

    return wav.fmtChannel


proc getSamplingFrequency*(wav: WAV): int32 =
    ##
    ## サンプリング周波数を取得
    ##
    ## wav WAV: wavオブジェクトを指定

    return wav.fmtBytesPerSec


proc getQuantizationBits*(wav: WAV): int16 =
    ##
    ## 量子化ビット数を取得
    ##
    ## wav WAV: wavオブジェクトを指定

    return wav.fmtBitsPerSample


proc divideBySilence*(wav: WAV, threshold: float, silenceTime: int): seq[WAV] =
    ##
    ## 無音部分でデータを分割します
    ##
    ## wav WAV: WAV構造体を指定します
    ## threshold float: 無音と識別するためのしきい値（0.0～1.0）
    ## silenceTime int: ここで指定した秒数無音が続けば分割を行う秒数

    var sequence: seq[float]
    var devidedData: seq[seq[float]]
    var silenceCount = 0

    for i in wav.data:
        sequence.add(i)
        
        # デシベルに変換し、0を最大値とする
        if getDecibel(i) <= getDecibel(threshold):
            silenceCount += 1
        else:
            silenceCount = 0
        
        # 無音がN秒以上続いたらそこでカットする
        if silenceCount >= int(wav.fmtBytesPerSec / wav.fmtBlockSize) * silenceTime:
            devidedData.add(sequence)

            sequence = @[]
            silenceCount = 0

    # 最後の端数のデータを付け足す
    if sequence.len > 0:
        devidedData.add(sequence)
    
    # WAVEデータを作っていく
    for i in devidedData:
        var wavTmp: WAV
        wavTmp.headerId = wav.headerId
        wavTmp.headerSize = wav.headerSize
        wavTmp.headerType = wav.headerType
        wavTmp.fmtId = wav.fmtId
        wavTmp.fmtSize = wav.fmtSize
        wavTmp.fmtFormat = wav.fmtFormat
        wavTmp.fmtChannel = wav.fmtChannel
        wavTmp.fmtSamplesPerSec = wav.fmtSamplesPerSec
        wavTmp.fmtBytesPerSec = wav.fmtBytesPerSec
        wavTmp.fmtBlockSize = wav.fmtBlockSize
        wavTmp.fmtBitsPerSample = wav.fmtBitsPerSample
        wavTmp.dataId = wav.dataId
        wavTmp.dataSize = int32(i.len * wav.fmtBlockSize)
        wavTmp.data.add(i)

        result.add(wavTmp)


proc isAllSilence*(wav: WAV, threshold: float): bool =
    ##
    ## WAVデータがすべて無音の場合はtrueを返し、有音が1箇所でもあればfalseを返します
    ##
    ## wav WAV: WAV構造体を指定します
    ## threshold float: 無音と識別するためのしきい値（0.0～1.0）

    for data in wav.data:
        if getDecibel(data) >= getDecibel(threshold):
            return false
    
    return true


proc trimSilence*(wav: WAV, threshold: float, leaveTopTime: float, leaveLastTime: float): WAV =
    ##
    ## wavデータの前後の無音をカットします
    ##
    ## wav WAV: WAV構造体を指定します
    ## threshold float: 無音と識別するためのしきい値（0.0～1.0）
    ## leaveTopTime float: 先頭に残す無音秒
    ## leaveLastTime float: 末尾に残す無音秒

    var confirmedData: seq[float]
    var tmp: seq[float]
    var startFlg = false

    # 先頭に残す無音のブロック数を計算 = 1秒のブロックサイズ（Byte） * 残す時間（秒）
    let leaveBlockNum = float(wav.fmtBytesPerSec) * leaveTopTime

    for data in wav.data:
        if startFlg == false and getDecibel(data) >= getDecibel(threshold):
            # 有音になったらフラグを立てる
            startFlg = true
        
        # 有音箇所は取得し続ける
        if startFlg == true:
            tmp.add(data)

            # 途中、無音が挟まったらその後最後まで無音の可能性もあるので、有音になってから最終確定用変数にデータを入れる
            if getDecibel(data) >= getDecibel(threshold):
                for t in tmp:
                    confirmedData.add(t)
                
                tmp = @[]

    # 最後の断片データ
    confirmedData.add(tmp)

    # データ完成後、前後に必要分の無音を入れる
    var silentData: seq[float]
    for i in 0..int(leaveBlockNum):
        # 無音をひたすら作る
        silentData.add(0.0)
    # 無音データを先頭に追加（insertが公式の書き方でエラるので愚直に書く）
    var tmpConfirmedData: seq[float]
    for i in silentData:
        tmpConfirmedData.add(i)
    for i in confirmedData:
        tmpConfirmedData.add(i)
    confirmedData = tmpConfirmedData

    
    # 返却用データ作成
    result.headerId = wav.headerId
    result.headerSize = wav.headerSize
    result.headerType = wav.headerType
    result.fmtId = wav.fmtId
    result.fmtSize = wav.fmtSize
    result.fmtFormat = wav.fmtFormat
    result.fmtChannel = wav.fmtChannel
    result.fmtSamplesPerSec = wav.fmtSamplesPerSec
    result.fmtBytesPerSec = wav.fmtBytesPerSec
    result.fmtBlockSize = wav.fmtBlockSize
    result.fmtBitsPerSample = wav.fmtBitsPerSample
    result.dataId = wav.dataId
    result.dataSize = int32(confirmedData.len * wav.fmtBlockSize)
    result.data = confirmedData
    


        
# ====================================================================
# 以下 private method
# ====================================================================

proc getDecibel(volume: float, fmtBitsPerSample: int = 16): float =
    ## 
    ## 与えられたボリューム値から、dB（デシベル）を計算し返します
    ## 
    ## dB = 20*log(|E|/E0)
    ## E0 = 2^(b-1)
    ## 参考： https://oshiete.goo.ne.jp/qa/1030807.html
    ##
    ## volume float: 音量
    ## fmtBitsPerSample int: サンプリングビット数

    if volume == 0:
        return -99999999999999.0

    let e0 = 2^(fmtBitsPerSample - 1) - 1       # 通常サンプリングビットは16として、32767.0が返るはず
    result = 20 * log10(abs(volume)) - log10(float(e0))