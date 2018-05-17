#!/bin/bash


TMP1=`mktemp`

number=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |awk -F "[:| ]" '/33520/{print $20}' |sort -u`

#微信企业号的CropID
CropID='wx80179d3a3eb675c2'
#企业号中发送告警的应用
Secret='rf8zW7iF-VECQVwKGndrHzAkEqfcnmSXmhIGUHCKH24'
GURL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$CropID&corpsecret=$Secret"
Gtoken=$(/usr/bin/curl -s -G $GURL |  awk -F "[\":,]" '{print $15}')
PURL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$Gtoken"

function body() {
    local int AppID=1
    #Appid 填写企业号中建立的报警APP的ID
    local UserID="@all"
    #此处填写报警接收用户，全部报警可留空
    local PartyID="@all"
    local TagID="@all"
    Ent=$'\n'
    Date=$(date '+%Y年%m月%d日 %H:%M:%S\n')
    Tit="服务器告警(V*P*N)"
    Content=`cat $TMP1`
    Msg=$Date$Ent$Tit$Ent$Content
    #Msg=$Date$Tit$Ent$(cat /tmp/message.txt|sed 's/%//g')
    #拼接msg主体文件,包含日期,主题,报警内容.并删除报警内容中的'%'号.
    #Url="http://www.zabbix.com"
    Pic="http://cdn.aixifan.com/dotnet/20130418/umeditor/dialogs/emotion/images/ac/35.gif"
    #Pic="http://cdn.aixifan.com/dotnet/20130418/umeditor/dialogs/emotion/images/ac2/24.gif"
    printf '{\n'
    printf '\t"touser": "'"$UserID"\"",\n"
    printf '\t"toparty": "'"$PartyID"\"",\n"
    printf '\t"totag": "'"$TagID"\"",\n"
    printf '\t"msgtype": "news",\n'
    printf '\t"agentid": "'" $AppID "\"",\n"
    printf '\t"news": {\n'
    printf '\t"articles": [\n'
    printf '{\n'
    printf '\t\t"title": "'"$Tit"\","\n"
    printf '\t\t"description": "'"$Msg"\","\n"
    printf '\t\t"url": "'"$Url"\","\n"
    printf '\t\t"picurl": "'"$Pic"\","\n"
    printf '\t}\n'
    printf '\t]\n'
    printf '\t}\n'
    printf '}\n'
}

echo $number| tr ' ' '\n' > $TMP1
if [[ `cat $TMP1|wc -l` -ge 3 ]];then
    curl -l -H "Content-type: application/json" -X POST -d "$(body )" $PURL
fi
rm -f $TMP1
