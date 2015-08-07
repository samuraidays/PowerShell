■前提
PowerShell2.0がインストールされていること
PowerCLI5.5がインストールされていること

■使い方
□スクリプトの実行方法
PowerShellを起動後、該当スクリプトを実行

※
実行ポリシーを変更していない場合は、下記コマンドでスクリプト実行を許可する

実行ポリシーを変更する(信頼されていないスクリプト実行を許可)
Set-ExecutionPolicy RemoteSigned

□ESXを新規構築した場合
listフォルダ内のesxlist.csvにホスト名、IPアドレスを追記する
この作業により、スクリプトの対象となります。

■そのほか
□スクリプトログ
スクリプトログは、logフォルダに出力されている

□認証情報
認証情報(アカウント、パスワード)がsecureフォルダに暗号化されて配置されている

□他スクリプトへの応用
foreach($ESX in $ESXHosts)で始まるループ処理の中で、
実際にPowerCLIコマンドを実行しています。
そのため、ESXにさせたい処理(情報取得、設定変更など)をこのループ内に記載すれば、
各ESXに対して、同じ処理をさせることができます。

PowerCLIコマンドやvSphere APIを使用可能

□パスワード変更時の対応
ESXのrootパスワードを変更した際に必要となります。
上記の際には、スクリプトで使用するパスワードファイルを新しいパスワードで作成する必要があります。
read-host -assecurestring | convertfrom-securestring | out-file C:\securepassword.dat
<新パスワードを入力して、エンターキー>

作成した新パスワードファイル(C:\securepassword.dat)をスクリプトフォルダ内の
secureフォルダにコピーします。

※
パスワードファイル(securepassword.dat)のファイル名や中身は変更しないこと。
