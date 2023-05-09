#!/bin/bash

echo "喵哥一键Trojan"

echo -e "欢迎使用喵哥trojan一键安装脚本！\n该脚本由喵哥提供技术支持，如有任何问题请联系TG：https://t.me/buyubei1"


# 安装必要软件
if [ -f /usr/bin/apt-get ]; then
	  apt-get update
	    apt-get install -y curl wget git unzip build-essential
    elif [ -f /usr/bin/yum ]; then
	      yum update
	        yum install -y curl wget git unzip make gcc
	else
		  echo "不支持的系统。"
		    exit 1
fi

# 设置时间同步
timedatectl set-ntp true

# 安装 Trojan
bash <(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)

# 生成全客户端订阅链接
echo "请输入您的域名或IP地址："
read domain

echo "请输入您的Trojan密码："
read password

echo "请输入用于生成订阅链接的路径："
read subpath

sub=$(cat <<EOF
{
	  "sub": [
	      {
		            "name": "喵哥的Trojan",
			          "type": "trojan",
				        "server": "$domain",
					      "port": 443,
					            "password": "$password",
						          "udp": false
							      },
						          {
								        "name": "喵哥的V2Ray",
									      "type": "vmess",
									            "server": "$domain",
										          "port": 443,
											        "uuid": "$(cat /proc/sys/kernel/random/uuid)",
												      "alterId": 64,
												            "cipher": "auto",
													          "tls": "tls"
														      }
													        ]
													}
												EOF
											)

											mkdir -p /usr/share/nginx/html$subpath
											echo "$sub" > /usr/share/nginx/html$subpath/sub.json
											ln -s /usr/share/nginx/html$subpath/sub.json /usr/share/nginx/html$subpath/trojan.txt

											echo "全客户端订阅链接已生成："
echo "https://$domain$subpath/trojan.txt"

# 安装 V2Ray
bash <(curl -fsSL https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 安装 Nginx
if [ -f /usr/bin/apt-get ]; then
  apt-get install -y nginx
elif [ -f /usr/bin/yum ]; then
  yum install -y nginx
fi

# 自动配置域名和 SSL 证书
echo "请输入您的域名："
read domain

echo "请输入您的邮箱地址："
read email

echo "正在申请 Let's Encrypt SSL 证书，请稍等..."

certbot certonly --standalone -d $domain --email $email --agree-tos -n

if [ $? -ne 0 ]; then
  echo "Let's Encrypt SSL 证书申请失败。"
  exit 1
fi

# 自动更新 TLS 证书
echo "0 12 * * * root certbot renew --post-hook \"systemctl reload nginx\"" >> /etc/crontab

# 自动更新 GeoIP 数据库
echo "0 0 * * * root /usr/bin/v2ray/geoipupdate -d /usr/bin/v2ray" >> /etc/crontab

# 自动校正 VPS 时间
echo "0 0 * * * root /usr/sbin/ntpdate pool.ntp

