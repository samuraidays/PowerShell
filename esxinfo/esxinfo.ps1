# ----------------------
# ESXサーバ情報取得スクリプト
# ----------------------
# 【機能概要】
#      PowerCLIコマンドを使用して、各ESXの仮想マシンリストや
#      ESXサーバのCPU、メモリ、データストアの情報を取得する
# 【引数】
#      なし
#      

# ----------------------
# 変数設定
# ----------------------
# このセクションでは、ESXリストファイルやログファイルなどの
# 設定を行います。
# 

# スクリプトのパス
$scriptpath=Split-Path $script:myInvocation.MyCommand.path -parent

# 情報を取得するESXサーバのリストファイル
$esxlistfile=$scriptpath + '\' + 'def\esxlist.csv'

# 取得したESX情報が出力されたファイルのパス
$outputpath=$scriptpath + '\' + 'list\'

# スクリプトログのパス
$logfile=$scriptpath + '\' + 'log\esxinfo.log'

# 出力されるファイルのファイル名
$vmfilename="getvmlist.txt"
$vmhostfilename="_getvmhost.txt"

# ESXパスワードファイルのパス
$passfile=$scriptpath + '\' + 'secure\securepassword.dat'

# ----------------------
# ログ出力用関数
# ----------------------
# 【機能概要】
#      メッセージを、画面とテキストファイルに追加書込みします。
#      出力時に日時を追加表示することも可能です。
# 【引数】
#      msg  表示するメッセージ
#      file 出力するテキストファイルの完全パス
#      dspTimeFlag メッセージへの日時に追加出力（0:追加しない, 1:追加する）
function msgOutput([String]$msg, [String]$logfile, [boolean]$dspTimeFlag) {
　if ($dspTimeFlag) {
　　$WkLogTimeMsg = Get-Date -format yyyy/MM/dd-HH:mm:ss
　　Write-Host ($msg + '  : ' + $WkLogTimeMsg)
　　Write-Output ($msg + '  : ' + $WkLogTimeMsg) | out-file $logfile -encoding Default -append
　} else {
　　Write-Host $msg
　　Write-Output  $msg | out-file $logfile -encoding  Default -append
　}
}

$dspTimeFlag=1

# ----------------------
# 処理の開始
# ----------------------
# 
clear-host

# ESXリストファイルの読み込み
if(Test-Path $esxlistfile){
	$esxcsv=Import-Csv $esxlistfile
} else {
	Write-Host "Listfile is no found"
}

# ESXリストファイルのIPアドレス列の取得
$ESXHosts=($esxcsv | %{$_.IPaddress}) | sort-object -unique

msgOutput "==== Script start ====" $logfile 0

# PowerCLI Snapinの読み込み
$out = Get-PSSnapin | Where-Object {$_.Name -like "vmware.vimautomation.core"}
if ($out -eq $null) {Add-PSSnapin vmware.vimautomation.core}

# ESXログインのための資格(アカウント)情報を取得
$vPass = cat $passfile | convertto-securestring
$esxcred = new-object -typename System.Management.Automation.PSCredential -argumentlist root, $vPass

$vmlistfile=$outputpath + 'vmlist\' + $vmfilename
get-date | Out-File -encoding default -FilePath $vmlistfile

# 各ESXに対して、ログイン、情報取得、ログアウトを実行
foreach($ESX in $ESXHosts){
    $out =Connect-VIServer -Server $ESX -Credential $esxcred  2>&1 | out-null
    if ($out -eq $null) { msgOutput "$ESX Connect" $logfile $dspTimeFlag } else {msgOutput "error:$ESX Connect" $logfile $dspTimeFlag}

    $vmhostfile=$outputpath + 'vmhost\' + $ESX + $vmhostfilename

    # ESX上の仮想マシン一覧の出力
    $out = get-vm | Select-Object VMHost,Name,PowerState,NumCpu,MemoryGB | Format-Table -auto | Out-File -encoding default -append -FilePath $vmlistfile
    if ($out -eq $null) { msgOutput "$ESX get-vm" $logfile $dspTimeFlag } else { msgOutput "error:$ESX get-vm" $logfile $dspTimeFlag }
    
　　# ESXのリソース情報(CPU,Memory)出力
    $out = get-vmhost | Select-Object Name,ConnectionState,NumCpu,MemoryUsageGB,MemoryTotalGB | Out-File -encoding default -FilePath $vmhostfile
    if ($out -eq $null) { msgOutput "$ESX get-vmhost" $logfile $dspTimeFlag } else {msgOutput "error:$ESX get-vmhost" $logfile $dspTimeFlag}

　　# ESXのリソース情報(データストア)出力
    $out = Get-datastore | Out-File -encoding default -FilePath $vmhostfile -append
    if ($out -eq $null) { msgOutput "$ESX get-datastore" $logfile $dspTimeFlag } else {msgOutput "error:$ESX get-datastore" $logfile $dspTimeFlag}

    # ESXからログアウト
    $out = Disconnect-VIServer -Server $ESX -confirm:$false
    if ($out -eq $null) { msgOutput "$ESX Disconnect" $logfile $dspTimeFlag } else {msgOutput "error:$ESX Disconnect" $logfile $dspTimeFlag}
}

msgOutput "==== Script finish ====" $logfile 0

