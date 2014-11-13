# ----------------------
# ESX�T�[�o���擾�X�N���v�g
# ----------------------
# �y�@�\�T�v�z
#      PowerCLI�R�}���h���g�p���āA�eESX�̉��z�}�V�����X�g��
#      ESX�T�[�o��CPU�A�������A�f�[�^�X�g�A�̏����擾����
# �y�����z
#      �Ȃ�
#      

# ----------------------
# �ϐ��ݒ�
# ----------------------
# ���̃Z�N�V�����ł́AESX���X�g�t�@�C���⃍�O�t�@�C���Ȃǂ�
# �ݒ���s���܂��B
# 

# �X�N���v�g�̃p�X
$scriptpath=Split-Path $script:myInvocation.MyCommand.path -parent

# �����擾����ESX�T�[�o�̃��X�g�t�@�C��
$esxlistfile=$scriptpath + '\' + 'def\esxlist.csv'

# �擾����ESX��񂪏o�͂��ꂽ�t�@�C���̃p�X
$outputpath=$scriptpath + '\' + 'list\'

# �X�N���v�g���O�̃p�X
$logfile=$scriptpath + '\' + 'log\esxinfo.log'

# �o�͂����t�@�C���̃t�@�C����
$vmfilename="getvmlist.txt"
$vmhostfilename="_getvmhost.txt"

# ESX�p�X���[�h�t�@�C���̃p�X
$passfile=$scriptpath + '\' + 'secure\securepassword.dat'

# ----------------------
# ���O�o�͗p�֐�
# ----------------------
# �y�@�\�T�v�z
#      ���b�Z�[�W���A��ʂƃe�L�X�g�t�@�C���ɒǉ������݂��܂��B
#      �o�͎��ɓ�����ǉ��\�����邱�Ƃ��\�ł��B
# �y�����z
#      msg  �\�����郁�b�Z�[�W
#      file �o�͂���e�L�X�g�t�@�C���̊��S�p�X
#      dspTimeFlag ���b�Z�[�W�ւ̓����ɒǉ��o�́i0:�ǉ����Ȃ�, 1:�ǉ�����j
function msgOutput([String]$msg, [String]$logfile, [boolean]$dspTimeFlag) {
�@if ($dspTimeFlag) {
�@�@$WkLogTimeMsg = Get-Date -format yyyy/MM/dd-HH:mm:ss
�@�@Write-Host ($msg + '  : ' + $WkLogTimeMsg)
�@�@Write-Output ($msg + '  : ' + $WkLogTimeMsg) | out-file $logfile -encoding Default -append
�@} else {
�@�@Write-Host $msg
�@�@Write-Output  $msg | out-file $logfile -encoding  Default -append
�@}
}

$dspTimeFlag=1

# ----------------------
# �����̊J�n
# ----------------------
# 
clear-host

# ESX���X�g�t�@�C���̓ǂݍ���
if(Test-Path $esxlistfile){
	$esxcsv=Import-Csv $esxlistfile
} else {
	Write-Host "Listfile is no found"
}

# ESX���X�g�t�@�C����IP�A�h���X��̎擾
$ESXHosts=($esxcsv | %{$_.IPaddress}) | sort-object -unique

msgOutput "==== Script start ====" $logfile 0

# PowerCLI Snapin�̓ǂݍ���
$out = Get-PSSnapin | Where-Object {$_.Name -like "vmware.vimautomation.core"}
if ($out -eq $null) {Add-PSSnapin vmware.vimautomation.core}

# ESX���O�C���̂��߂̎��i(�A�J�E���g)�����擾
$vPass = cat $passfile | convertto-securestring
$esxcred = new-object -typename System.Management.Automation.PSCredential -argumentlist root, $vPass

$vmlistfile=$outputpath + 'vmlist\' + $vmfilename
get-date | Out-File -encoding default -FilePath $vmlistfile

# �eESX�ɑ΂��āA���O�C���A���擾�A���O�A�E�g�����s
foreach($ESX in $ESXHosts){
    $out =Connect-VIServer -Server $ESX -Credential $esxcred  2>&1 | out-null
    if ($out -eq $null) { msgOutput "$ESX Connect" $logfile $dspTimeFlag } else {msgOutput "error:$ESX Connect" $logfile $dspTimeFlag}

    $vmhostfile=$outputpath + 'vmhost\' + $ESX + $vmhostfilename

    # ESX��̉��z�}�V���ꗗ�̏o��
    $out = get-vm | Select-Object VMHost,Name,PowerState,NumCpu,MemoryGB | Format-Table -auto | Out-File -encoding default -append -FilePath $vmlistfile
    if ($out -eq $null) { msgOutput "$ESX get-vm" $logfile $dspTimeFlag } else { msgOutput "error:$ESX get-vm" $logfile $dspTimeFlag }
    
�@�@# ESX�̃��\�[�X���(CPU,Memory)�o��
    $out = get-vmhost | Select-Object Name,ConnectionState,NumCpu,MemoryUsageGB,MemoryTotalGB | Out-File -encoding default -FilePath $vmhostfile
    if ($out -eq $null) { msgOutput "$ESX get-vmhost" $logfile $dspTimeFlag } else {msgOutput "error:$ESX get-vmhost" $logfile $dspTimeFlag}

�@�@# ESX�̃��\�[�X���(�f�[�^�X�g�A)�o��
    $out = Get-datastore | Out-File -encoding default -FilePath $vmhostfile -append
    if ($out -eq $null) { msgOutput "$ESX get-datastore" $logfile $dspTimeFlag } else {msgOutput "error:$ESX get-datastore" $logfile $dspTimeFlag}

    # ESX���烍�O�A�E�g
    $out = Disconnect-VIServer -Server $ESX -confirm:$false
    if ($out -eq $null) { msgOutput "$ESX Disconnect" $logfile $dspTimeFlag } else {msgOutput "error:$ESX Disconnect" $logfile $dspTimeFlag}
}

msgOutput "==== Script finish ====" $logfile 0

