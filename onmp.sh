#!/bin/sh
# @Author: xzhih
# @Date:   2017-07-29 06:10:54
# @Last Modified by:   Fangshing87
# @Last Modified time: 2019-06-09 11:39:26

# 软件包列表
pkglist="wget unzip grep sed tar ca-certificates coreutils-whoami php7 php7-cgi php7-cli php7-fastcgi php7-fpm php7-mod-mysqli php7-mod-pdo php7-mod-pdo-mysql nginx-extras mariadb-server mariadb-server-extra mariadb-client mariadb-client-extra"

phpmod="php7-mod-calendar php7-mod-ctype php7-mod-curl php7-mod-dom php7-mod-exif php7-mod-fileinfo php7-mod-ftp php7-mod-gd php7-mod-gettext php7-mod-gmp php7-mod-hash php7-mod-iconv php7-mod-intl php7-mod-json php7-mod-ldap php7-mod-session php7-mod-mbstring php7-mod-opcache php7-mod-openssl php7-mod-pcntl php7-mod-phar php7-pecl-redis php7-mod-session php7-mod-shmop php7-mod-simplexml php7-mod-snmp php7-mod-soap php7-mod-sockets php7-mod-sqlite3 php7-mod-sysvmsg php7-mod-sysvsem php7-mod-sysvshm php7-mod-tokenizer php7-mod-xml php7-mod-xmlreader php7-mod-xmlwriter php7-mod-zip php7-pecl-dio php7-pecl-http php7-pecl-libevent php7-pecl-propro php7-pecl-raphf redis snmpd snmp-mibs snmp-utils zoneinfo-core zoneinfo-asia"

# 后续可能增加的包(缺少源支持)
# php7-mod-imagick imagemagick imagemagick-jpeg imagemagick-png imagemagick-tiff imagemagick-tools

# Web程序
# (1) phpMyAdmin（数据库管理工具）
url_phpMyAdmin="https://files.phpmyadmin.net/phpMyAdmin/4.8.3/phpMyAdmin-4.8.3-all-languages.zip"

# (2) WordPress（使用最广泛的CMS）
url_WordPress="https://cn.wordpress.org/wordpress-4.9.4-zh_CN.zip"

# (3) Owncloud（经典的私有云）
url_Owncloud="https://download.owncloud.org/community/owncloud-10.0.10.zip"

# (4) Nextcloud（Owncloud团队的新作，美观强大的个人云盘）
url_Nextcloud="https://download.nextcloud.com/server/releases/nextcloud-18.0.3.zip"

# (5) h5ai（优秀的文件目录）
url_h5ai="https://release.larsjung.de/h5ai/h5ai-0.29.0.zip"

# (6) Lychee（一个很好看，易于使用的Web相册）
url_Lychee="https://github.com/electerious/Lychee/archive/master.zip"

# (7) Kodexplorer（可道云aka芒果云在线文档管理器）
url_Kodexplorer="http://static.kodcloud.com/update/download/kodexplorer4.36.zip"

# (8) Typecho (流畅的轻量级开源博客程序)
url_Typecho="http://typecho.org/downloads/1.1-17.10.30-release.tar.gz"

# (9) Z-Blog (体积小，速度快的PHP博客程序)
url_Zblog="https://update.zblogcn.com/zip/Z-BlogPHP_1_5_2_1935_Zero.zip"

# (10) DzzOffice (开源办公平台)
url_DzzOffice="https://codeload.github.com/zyx0814/dzzoffice/zip/master"

# 通用环境变量获取
get_env()
{
    # 获取用户名
    if [[ $USER ]]; then
        username=$USER
    elif [[ -n $(whoami 2>/dev/null) ]]; then
        username=$(whoami 2>/dev/null)
    else
        username=$(cat /etc/passwd | sed "s/:/ /g" | awk 'NR==1'  | awk '{printf $1}')
    fi

    # 获取路由器IP
    localhost=$(ifconfig  | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}' | awk 'NR==1')
    if [[ ! -n "$localhost" ]]; then
        localhost="你的路由器IP"
    fi
}

##### 软件包状态检测 #####
install_check()
{
    notinstall=""
    for data in $pkglist ; do
        if [[ `opkg list-installed | grep $data | wc -l` -ne 0 ]];then
            echo "$data 已安装"
        else
            notinstall="$notinstall $data"
            echo "$data 正在安装..."
            opkg install $data
        fi
    done
}

# 安装PHP mod 
install_php_mod()
{
    notinstall=""
    for data in $phpmod ; do
        if [[ `opkg list-installed | grep $data | wc -l` -ne 0 ]];then
            echo "$data 已安装"
        else
            notinstall="$notinstall $data"
            echo "$data 正在安装..."
            opkg install $data
        fi
    done
}

############## 安装软件包 #############
install_onmp_ipk()
{
    opkg update

    # 软件包状态检测
    install_check

    for i in 'seq 3'; do
        if [[ ${#notinstall} -gt 0 ]]; then
            install_check
        fi
    done

    if [[ ${#notinstall} -gt 0 ]]; then
        echo "可能会因为某些问题某些核心软件包无法安装，请保持/opt/目录足够干净，如果是网络问题，请挂全局VPN再次运行命令"
    else
        echo "----------------------------------------"
        echo "|********** ONMP软件包已完整安装 *********|"
        echo "----------------------------------------"
        echo "是否安装PHP的模块(Nextcloud这类应用需要)，你也可以手动安装"
#
read -p "输入你的选择[y/n]: " input
case $input in
    y) install_php_mod;;
n) echo "如果程序提示需要安装插件，你可以自行使用opkg命令安装";;
*) echo "你输入的不是 y/n"
exit;;
esac 
        echo "现在开始初始化ONMP"
        init_onmp
        echo ""
    fi
}

################ 初始化onmp ###############
init_onmp()
{
    # 初始化网站目录
    rm -rf /opt/wwwroot
    mkdir -p /opt/wwwroot/default
    chmod -R 777 /opt/tmp

    # 初始化Nginx
    init_nginx > /dev/null 2>&1

    # 初始化数据库
    init_sql > /dev/null 2>&1

    # 初始化PHP
    init_php > /dev/null 2>&1

    # 初始化redis
    echo 'unixsocket /opt/var/run/redis.sock' >> /opt/etc/redis.conf
    echo 'unixsocketperm 777' >> /opt/etc/redis.conf 

    # 添加探针
    cp /opt/onmp/tz.php /opt/wwwroot/default -R
    add_vhost 81 default
    sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/default.conf
    chmod -R 777 /opt/wwwroot/default

    # 生成ONMP命令
    set_onmp_sh
    onmp start
}

############### 初始化Nginx ###############
init_nginx()
{
    get_env
    /opt/etc/init.d/S80nginx stop > /dev/null 2>&1
    rm -rf /opt/etc/nginx/vhost 
    rm -rf /opt/etc/nginx/conf
    mkdir -p /opt/etc/nginx/vhost
    mkdir -p /opt/etc/nginx/conf

# 初始化nginx配置文件
cat > "/opt/etc/nginx/nginx.conf" <<-\EOF
user theOne root;
pid /opt/var/run/nginx.pid;
worker_processes auto;

events {
    use epoll;
    multi_accept on;
    worker_connections 1024;
}

http {
    charset utf-8;
    include mime.types;
    default_type application/octet-stream;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 60;
    
    client_max_body_size 2000m;
    client_body_temp_path /opt/tmp/;
    
    gzip on; 
    gzip_vary on;
    gzip_proxied any;
    gzip_min_length 1k;
    gzip_buffers 4 8k;
    gzip_comp_level 2;
    gzip_disable "msie6";
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript image/svg+xml;

    include /opt/etc/nginx/vhost/*.conf;
}
EOF

sed -e "s/theOne/$username/g" -i /opt/etc/nginx/nginx.conf

# 特定程序的nginx配置
nginx_special_conf

}

##### 特定程序的nginx配置 #####
nginx_special_conf()
{
# php-fpm
cat > "/opt/etc/nginx/conf/php-fpm.conf" <<-\OOO
location ~ \.php(?:$|/) {
    fastcgi_split_path_info ^(.+\.php)(/.+)$; 
    fastcgi_pass unix:/opt/var/run/php7-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
OOO

# nextcloud
cat > "/opt/etc/nginx/conf/nextcloud.conf" <<-\OOO
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header Referrer-Policy no-referrer;
    fastcgi_hide_header X-Powered-By;
    root /config/www/nextcloud/;
    # display real ip in nginx logs when connected through reverse proxy via docker network
    set_real_ip_from 172.0.0.0/8;
    real_ip_header X-Forwarded-For;
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    location = /.well-known/carddav {
      return 301 $scheme://$host:$server_port/remote.php/dav;
    }
    location = /.well-known/caldav {
      return 301 $scheme://$host:$server_port/remote.php/dav;
    }
    client_max_body_size 10G;
    fastcgi_buffers 64 4K;
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
    location / {
        rewrite ^ /index.php;
    }
    location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
        deny all;
    }
    location ~ ^\/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }
    location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:$|\/) {
        fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
        set $path_info $fastcgi_path_info;
        try_files $fastcgi_script_name =404;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $path_info;
        fastcgi_param HTTPS on;
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }
    location ~ ^\/(?:updater|oc[ms]-provider)(?:$|\/) {
        try_files $uri/ =404;
        index index.php;
    }
    location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
        try_files $uri /index.php$request_uri;
        add_header Cache-Control "public, max-age=15778463";
        # Add headers to serve security related headers
        # Before enabling Strict-Transport-Security headers please read into this
        # topic first.
        #add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
        #
        # WARNING: Only add the preload option once you read about
        # the consequences in https://hstspreload.org/. This option
        # will add the domain to a hardcoded list that is shipped
        # in all major browsers and getting removed from this list
        # could take several months.
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;
        access_log off;
    }
    location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap)$ {
        try_files $uri /index.php$request_uri;
        access_log off;
    }
}
OOO

# owncloud
cat > "/opt/etc/nginx/conf/owncloud.conf" <<-\OOO
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options "SAMEORIGIN";
add_header X-XSS-Protection "1; mode=block";
add_header X-Robots-Tag none;
add_header X-Download-Options noopen;
add_header X-Permitted-Cross-Domain-Policies none;

location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
}
location = /.well-known/carddav {
    return 301 $scheme://$host/remote.php/dav;
}
location = /.well-known/caldav {
    return 301 $scheme://$host/remote.php/dav;
}

gzip off;
fastcgi_buffers 8 4K; 
fastcgi_ignore_headers X-Accel-Buffering;
error_page 403 /core/templates/403.php;
error_page 404 /core/templates/404.php;

location / {
    rewrite ^ /index.php$uri;
}

location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
    return 404;
}
location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
    return 404;
}

location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\.php(?:$|/) {
    fastcgi_split_path_info ^(.+\.php)(/.*)$;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param SCRIPT_NAME $fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_param modHeadersAvailable true;
    fastcgi_param front_controller_active true;
    fastcgi_read_timeout 180;
    fastcgi_pass unix:/opt/var/run/php7-fpm.sock;
    fastcgi_intercept_errors on;
    fastcgi_request_buffering on;
}

location ~ ^/(?:updater|ocs-provider)(?:$|/) {
    try_files $uri $uri/ =404;
    index index.php;
}

location ~ \.(?:css|js)$ {
    try_files $uri /index.php$uri$is_args$args;
    add_header Cache-Control "max-age=15778463";
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    access_log off;
}

location ~ \.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg|map)$ {
    add_header Cache-Control "public, max-age=7200";
    try_files $uri /index.php$uri$is_args$args;
    access_log off;
}
OOO

# wordpress
cat > "/opt/etc/nginx/conf/wordpress.conf" <<-\OOO
location = /favicon.ico {
    log_not_found off;
    access_log off;
}
location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
}
location ~ /\. {
    deny all;
}
location ~ ^/wp-content/uploads/.*\.php$ {
    deny all;
}
location ~* /(?:uploads|files)/.*\.php$ {
    deny all;
}

location / {
    try_files $uri $uri/ /index.php?$args;
}

location ~ \.php$ {
    include fastcgi.conf;
    fastcgi_intercept_errors on;
    fastcgi_pass unix:/opt/var/run/php7-fpm.sock;
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;
}

location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    expires max;
    log_not_found off;
}
OOO

# typecho
cat > "/opt/etc/nginx/conf/typecho.conf" <<-\OOO
if (!-e $request_filename) {
        rewrite ^(.*)$ /index.php$1 last;
    }
OOO

}

############## 重置、初始化MySQL #############
init_sql()
{
    get_env
    /opt/etc/init.d/S70mysqld stop > /dev/null 2>&1
    sleep 10
    killall mysqld > /dev/null 2>&1
    rm -rf /opt/mysql
    rm -rf /opt/var/mysql
    mkdir -p /opt/etc/mysql/

# MySQL设置
cat > "/opt/etc/mysql/my.cnf" <<-\MMM
[client-server]
port               = 3306
socket             = /opt/var/run/mysqld.sock

[mysqld]
user               = theOne
socket             = /opt/var/run/mysqld.sock
pid-file           = /opt/var/run/mysqld.pid
basedir            = /opt
lc_messages_dir    = /opt/share/mariadb
lc_messages        = en_US
innodb_use_native_aio = 0
datadir            = /opt/var/mysql/
tmpdir             = /opt/tmp/

skip-external-locking

bind-address       = 127.0.0.1

key_buffer_size    = 24M
max_allowed_packet = 24M
thread_stack       = 192K
thread_cache_size  = 8

[mysqldump]
quick
quote-names
max_allowed_packet = 24M

[mysql]
#no-auto-rehash

[isamchk]
key_buffer_size    = 24M

[mysqlhotcopy]
interactive-timeout
MMM

sed -e "s/theOne/$username/g" -i /opt/etc/mysql/my.cnf

chmod 644 /opt/etc/mysql/my.cnf

mkdir -p /opt/var/mysql

# 数据库安装
/opt/bin/mysql_install_db --user=$username --basedir=/opt --datadir=/opt/var/mysql/
echo -e "\n正在初始化数据库，请稍等1分钟"
sleep 20

# 初次启动MySQL
/opt/etc/init.d/S70mysqld start
sleep 60

# 设置数据库密码
mysqladmin -u root password 123456
echo -e "\033[41;37m 数据库用户：root, 初始密码：123456 \033[0m"
onmp restart
}

############## PHP初始化 #############
init_php()
{
# PHP7设置 
/opt/etc/init.d/S79php7-fpm stop > /dev/null 2>&1

mkdir -p /opt/usr/php/tmp/
chmod -R 777 /opt/usr/php/tmp/

sed -e "/^doc_root/d" -i /opt/etc/php.ini
sed -e "s/.*memory_limit = .*/memory_limit = 128M/g" -i /opt/etc/php.ini
sed -e "s/.*output_buffering = .*/output_buffering = 4096/g" -i /opt/etc/php.ini
sed -e "s/.*post_max_size = .*/post_max_size = 8000M/g" -i /opt/etc/php.ini
sed -e "s/.*max_execution_time = .*/max_execution_time = 2000 /g" -i /opt/etc/php.ini
sed -e "s/.*upload_max_filesize.*/upload_max_filesize = 8000M/g" -i /opt/etc/php.ini
sed -e "s/.*listen.mode.*/listen.mode = 0666/g" -i /opt/etc/php7-fpm.d/www.conf

# PHP配置文件
cat >> "/opt/etc/php.ini" <<-\PHPINI
session.save_path = "/opt/usr/php/tmp/"
opcache.enable=1
opcache.enable_cli=1
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.memory_consumption=128
opcache.save_comments=1
opcache.revalidate_freq=60
opcache.fast_shutdown=1

mysqli.default_socket=/opt/var/run/mysqld.sock
pdo_mysql.default_socket=/opt/var/run/mysqld.sock
PHPINI

cat >> "/opt/etc/php7-fpm.d/www.conf" <<-\PHPFPM
env[HOSTNAME] = $HOSTNAME
env[PATH] = /opt/bin:/usr/local/bin:/usr/bin:/bin
env[TMP] = /opt/tmp
env[TMPDIR] = /opt/tmp
env[TEMP] = /opt/tmp
PHPFPM
}

############# 用户设置数据库密码 ############
set_passwd()
{
    /opt/etc/init.d/S70mysqld start
    sleep 3
    echo -e "\033[41;37m 初始密码：123456 \033[0m"
    mysqladmin -u root -p password
    onmp restart
}

################ 卸载onmp ###############
remove_onmp()
{
    /opt/etc/init.d/S70mysqld stop > /dev/null 2>&1
    /opt/etc/init.d/S79php7-fpm stop > /dev/null 2>&1
    /opt/etc/init.d/S80nginx stop > /dev/null 2>&1
    /opt/etc/init.d/S70redis stop > /dev/null 2>&1
    killall -9 nginx mysqld php-fpm redis-server > /dev/null 2>&1
    for pkg in $pkglist; do
        opkg remove $pkg --force-depends
    done
    for mod in $phpmod; do
        opkg remove $mod --force-depends
    done
    rm -rf /opt/wwwroot
    rm -rf /opt/etc/nginx/vhost
    rm -rf /opt/bin/onmp
    rm -rf /opt/mysql
    rm -rf /opt/var/mysql
    rm -rf /opt/etc/nginx/
    rm -rf /opt/etc/php*
    rm -rf /opt/etc/mysql
    rm -rf /opt/etc/redis*
}

################ 生成ONMP命令 ###############
set_onmp_sh()
{
# 删除
rm -rf /opt/bin/onmp

# 写入文件
cat > "/opt/bin/onmp" <<-\EOF
#!/bin/sh

# 获取路由器IP
localhost=$(ifconfig | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}' | awk 'NR==1')
if [[ ! -n "$localhost" ]]; then
    localhost="你的路由器IP"
fi

vhost_list()
{
    echo "网站列表："
    logger -t "【ONMP】" "网站列表："
    for conf in /opt/etc/nginx/vhost/*;
    do
        path=$(cat $conf | awk 'NR==4' | awk '{print $2}' | sed 's/;//')
        port=$(cat $conf | awk 'NR==2' | awk '{print $2}' | sed 's/;//')
        echo "$path        $localhost:$port"
        logger -t "【ONMP】" "$path     $localhost:$port"
    done
    echo "浏览器地址栏输入：$localhost:81 查看php探针"
}

onmp_restart()
{
    /opt/etc/init.d/S70mysqld stop > /dev/null 2>&1
    /opt/etc/init.d/S79php7-fpm stop > /dev/null 2>&1
    /opt/etc/init.d/S80nginx stop > /dev/null 2>&1
    killall -9 nginx mysqld php-fpm > /dev/null 2>&1
    sleep 3
    /opt/etc/init.d/S70mysqld start > /dev/null 2>&1
    /opt/etc/init.d/S79php7-fpm start > /dev/null 2>&1
    /opt/etc/init.d/S80nginx start > /dev/null 2>&1
    sleep 3
    num=0
    for PROC in 'nginx' 'php-fpm' 'mysqld'; do 
        if [ -n "`pidof $PROC`" ]; then
            echo $PROC "启动成功";
        else
            echo $PROC "启动失败";
            num=`expr $num + 1`
        fi 
    done

    if [[ $num -gt 0 ]]; then
        echo "onmp启动失败"
        logger -t "【ONMP】" "启动失败"
    else
        echo "onmp已启动"
        logger -t "【ONMP】" "已启动"
        vhost_list
    fi
}

case $1 in
    open ) 
    /opt/onmp/onmp.sh
    ;;

    start )
    echo "onmp正在启动"
    logger -t "【ONMP】" "正在启动"
    onmp_restart
    ;;

    stop )
    echo "onmp正在停止"
    logger -t "【ONMP】" "正在停止"
    /opt/etc/init.d/S70mysqld stop > /dev/null 2>&1
    /opt/etc/init.d/S79php7-fpm stop > /dev/null 2>&1
    /opt/etc/init.d/S80nginx stop > /dev/null 2>&1
    echo "onmp已停止"
    logger -t "【ONMP】" "已停止"
    ;;

    restart )
    echo "onmp正在重启"
    logger -t "【ONMP】" "正在重启"
    onmp_restart
    ;;

    mysql )
    case $2 in
        start ) /opt/etc/init.d/S70mysqld start;;
        stop ) /opt/etc/init.d/S70mysqld stop;;
        restart ) /opt/etc/init.d/S70mysqld restart;;
        * ) echo "onmp mysqld start|restart|stop";;
    esac
    ;;

    php )
    case $2 in
        start ) /opt/etc/init.d/S79php7-fpm start;;
        stop ) /opt/etc/init.d/S79php7-fpm stop;;
        restart ) /opt/etc/init.d/S79php7-fpm restart;;
        * ) echo "onmp php start|restart|stop";;
    esac
    ;;

    nginx )
    case $2 in
        start ) /opt/etc/init.d/S80nginx start;;
        stop ) /opt/etc/init.d/S80nginx stop;;
        restart ) /opt/etc/init.d/S80nginx restart;;
        * ) echo "onmp nginx start|restart|stop";;
    esac
    ;;

    redis )
    case $2 in
        start ) /opt/etc/init.d/S70redis start;;
        stop ) /opt/etc/init.d/S70redis stop;;
        restart ) /opt/etc/init.d/S70redis restart;;
        * ) echo "onmp redis start|restart|stop";;
    esac
    ;;

    list )
    vhost_list
    ;;
    * )
#
cat << HHH
=================================
 onmp 管理命令
 onmp open

 启动 停止 重启
 onmp start|stop|restart

 查看网站列表 onmp list

 Nginx 管理命令
 onmp nginx start|restart|stop
 MySQL 管理命令
 onmp mysql start|restart|stop
 PHP 管理命令
 onmp php start|restart|stop
 Redis 管理命令
 onmp redis start|restart|stop
=================================
HHH
    ;;
esac
EOF

chmod +x /opt/bin/onmp
#
cat << HHH
=================================
 onmp 管理命令
 onmp open

 启动 停止 重启
 onmp start|stop|restart

 查看网站列表 onmp list

 Nginx 管理命令
 onmp nginx start|restart|stop
 MySQL 管理命令
 onmp mysql start|restart|stop
 PHP 管理命令
 onmp php start|restart|stop
 Redis 管理命令
 onmp redis start|restart|stop
=================================
HHH

}

############### 网站程序安装 ##############
install_website()
{
    # 通用环境变量获取
    get_env
    clear
    chmod -R 777 /opt/tmp
# 选择程序
cat << AAA
----------------------------------------
|************* 选择WEB程序 *************|
----------------------------------------
(1) phpMyAdmin（数据库管理工具）
(2) WordPress（使用最广泛的CMS）
(3) Owncloud（经典的私有云）
(4) Nextcloud（Owncloud团队的新作，美观强大的个人云盘）
(5) h5ai（优秀的文件目录）
(6) Lychee（一个很好看，易于使用的Web相册）
(7) Kodexplorer（可道云aka芒果云在线文档管理器）
(8) Typecho (流畅的轻量级开源博客程序)
(9) Z-Blog (体积小，速度快的PHP博客程序)
(10) DzzOffice (开源办公平台)
(0) 退出
AAA
read -p "输入你的选择[0-11]: " input
case $input in
    1) install_phpmyadmin;;
2) install_wordpress;;
3) install_owncloud;;
4) install_nextcloud;;
5) install_h5ai;;
6) install_lychee;;
7) install_kodexplorer;;
8) install_typecho;;
9) install_zblog;;
10) install_dzzoffice;;
0) exit;;
*) echo "你输入的不是 0 ~ 10 之间的!"
break;;
esac
}

############### WEB程序安装器 ##############
web_installer()
{
    clear
    echo "----------------------------------------"
    echo "|***********  WEB程序安装器  ***********|"
    echo "----------------------------------------"
    echo "安装 $name："

    # 获取用户自定义设置
    read -p "输入服务端口（请避开已使用的端口）[留空默认$port]: " nport
    if [[ $nport ]]; then
        port=$nport
    fi
    read -p "输入目录名（留空默认：$name）: " webdir
    if [[ ! -n "$webdir" ]]; then
        webdir=$name
    fi

    # 检查目录是否存在
    if [[ ! -d "/opt/wwwroot/$webdir" ]] ; then
        echo "开始安装..."
    else
        read -p "网站目录 /opt/wwwroot/$webdir 已存在，是否删除: [y/n(小写)]" ans
        case $ans in
            y ) rm -rf /opt/wwwroot/$webdir; echo "已删除";;
n ) echo "未删除";;
* ) echo "没有这个选项"; exit;;
esac
fi

    # 下载程序并解压
    suffix="zip"
    if [[ -n "$istar" ]]; then
        suffix="tar"
    fi
    if [[ ! -d "/opt/wwwroot/$webdir" ]] ; then
        rm -rf /opt/etc/nginx/vhost/$webdir.conf
        if [[ ! -f /opt/wwwroot/$name.$suffix ]]; then
            rm -rf /opt/tmp/$name.$suffix
            wget --no-check-certificate -O /opt/tmp/$name.$suffix $filelink
            mv /opt/tmp/$name.* /opt/wwwroot/
        fi
        if [[ ! -f "/opt/wwwroot/$name.$suffix" ]]; then
            echo "下载未成功"
        else
            echo "正在解压..."
            if [[ -n "$hookdir" ]]; then
                mkdir /opt/wwwroot/$hookdir
            fi

            if [[ -n "$istar" ]]; then
                tar zxf /opt/wwwroot/$name.$suffix -C /opt/wwwroot/$hookdir > /dev/null 2>&1
            else
                unzip /opt/wwwroot/$name.$suffix -d /opt/wwwroot/$hookdir > /dev/null 2>&1
            fi
            
            mv /opt/wwwroot/$dirname /opt/wwwroot/$webdir
            echo "解压完成..."
        fi
    fi

    # 检测是否解压成功
    if [[ ! -d "/opt/wwwroot/$webdir" ]] ; then
        echo "安装未成功"
        exit
    fi
}

# 安装脚本的基本结构
# install_webapp()
# {
#     # 默认配置
#     filelink=""         # 下载链接
#     name=""             # 程序名
#     dirname=""          # 解压后的目录名
#     port=               # 端口
#     hookdir=$dirname    # 某些程序解压后不是单个目录，用这个hook解决
#     istar=true          # 是否为tar压缩包, 不是则删除此行

#     # 运行安装程序 
#     web_installer
#     echo "正在配置$name..."
#     # chmod -R 777 /opt/wwwroot/$webdir     # 目录权限看情况使用

#     # 添加到虚拟主机
#     add_vhost $port $webdir
#     sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf         # 添加公共php-fpm支持
#     onmp restart >/dev/null 2>&1
#     echo "$name安装完成"
#     echo "浏览器地址栏输入：$localhost:$port 即可访问"
# }

############# 安装phpMyAdmin ############
install_phpmyadmin()
{
    # 默认配置
    filelink=$url_phpMyAdmin
    name="phpMyAdmin"
    dirname="phpMyAdmin-*-languages"
    port=82

    # 运行安装程序
    web_installer 
    echo "正在配置$name..."
    cp /opt/wwwroot/$webdir/config.sample.inc.php /opt/wwwroot/$webdir/config.inc.php
    chmod 644 /opt/wwwroot/$webdir/config.inc.php
    mkdir -p /opt/wwwroot/$webdir/tmp
    chmod 777 /opt/wwwroot/$webdir/tmp
    sed -e "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = 'onmponmponmponmponmponmponmponmp';/g" -i /opt/wwwroot/$webdir/config.inc.php

    # 添加到虚拟主机
    add_vhost $port $webdir
    sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "phpMyaAdmin的用户、密码就是数据库用户、密码"
}

############# 安装WordPress ############
install_wordpress()
{
    # 默认配置
    filelink=$url_WordPress
    name="WordPress"
    dirname="wordpress"
    port=83

    # 运行安装程序
    web_installer
    echo "正在配置$name..."
    chmod -R 777 /opt/wwwroot/$webdir

    # 添加到虚拟主机
    add_vhost $port $webdir
    # WordPress的配置文件中有php-fpm了, 不需要外部引入
    sed -e "s/.*\#otherconf.*/    include \/opt\/etc\/nginx\/conf\/wordpress.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "可以用phpMyaAdmin建立数据库，然后在这个站点上一步步配置网站信息"
}

############### 安装h5ai ##############
install_h5ai()
{
    # 默认配置
    filelink=$url_h5ai
    name="h5ai"
    dirname="_h5ai"
    port=85
    hookdir=$dirname

    # 运行安装程序
    web_installer
    echo "正在配置$name..."
    cp /opt/wwwroot/$webdir/_h5ai/README.md /opt/wwwroot/$webdir/
    chmod -R 777 /opt/wwwroot/$webdir/

    # 添加到虚拟主机
    add_vhost $port $webdir
    sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    sed -e "s/.*\index index.html.*/    index  index.html  index.php  \/_h5ai\/public\/index.php;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "配置文件在/opt/wwwroot/$webdir/_h5ai/private/conf/options.json"
    echo "你可以通过修改它来获取更多功能"
}

################ 安装Lychee ##############
install_lychee()
{
    # 默认配置
    filelink=$url_Lychee
    name="Lychee"
    dirname="Lychee-master"
    port=86

    # 运行安装程序
    web_installer
    echo "正在配置$name..."
    chmod -R 777 /opt/wwwroot/$webdir/uploads/ /opt/wwwroot/$webdir/data/

    # 添加到虚拟主机
    add_vhost $port $webdir
    sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "首次打开会要配置数据库信息"
    echo "地址：127.0.0.1 用户、密码你自己设置的或者默认是root 123456"
    echo "下面的可以不配置，然后下一步创建个用户就可以用了"
}

################# 安装Owncloud ###############
install_owncloud()
{
    # 默认配置
    filelink=$url_Owncloud     
    name="Owncloud"         
    dirname="owncloud"      
    port=98

    # 运行安装程序 
    web_installer
    echo "正在配置$name..."
    chmod -R 777 /opt/wwwroot/$webdir

    # 添加到虚拟主机
    add_vhost $port $webdir
    # Owncloud的配置文件中有php-fpm了, 不需要外部引入
    sed -e "s/.*\#otherconf.*/    include \/opt\/etc\/nginx\/conf\/owncloud.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf

    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "首次打开会要配置用户和数据库信息"
    echo "地址默认 localhost 用户、密码你自己设置的或者默认是root 123456"
    echo "安装好之后可以点击左上角三条杠进入market安装丰富的插件，比如在线预览图片、视频等"
    echo "需要先在 web 界面配置完成后，才能使用 onmp open 的第 10 个选项开启 Redis"
}

################# 安装Nextcloud ##############
install_nextcloud()
{
    # 默认配置
    filelink=$url_Nextcloud
    name="Nextcloud"
    dirname="nextcloud"
    port=99

    # 运行安装程序
    web_installer   
    echo "正在配置$name..."
    chmod -R 777 /opt/wwwroot/$webdir

    # 添加到虚拟主机
    add_vhost $port $webdir
    # nextcloud的配置文件中有php-fpm了, 不需要外部引入
    sed -e "s/.*\#otherconf.*/    include \/opt\/etc\/nginx\/conf\/nextcloud.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf

    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "首次打开会要配置用户和数据库信息"
    echo "地址默认 localhost 用户、密码你自己设置的或者默认是root 123456"
    echo "需要先在 web 界面配置完成后，才能使用 onmp open 的第 10 个选项开启 Redis"
}

############## 安装kodexplorer芒果云 ##########
install_kodexplorer()
{
    # 默认配置
    filelink=$url_Kodexplorer
    name="Kodexplorer"
    dirname="kodexplorer"
    port=88
    hookdir=$dirname

    # 运行安装程序 
    web_installer
    echo "正在配置$name..."
    chmod -R 777 /opt/wwwroot/$webdir

    # 添加到虚拟主机
    add_vhost $port $webdir
    sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
}

############# 安装Typecho ############
install_typecho()
{
    # 默认配置
    filelink=$url_Typecho
    name="Typecho"
    dirname="build"
    port=90
    istar=true

    # 运行安装程序 
    web_installer
    echo "正在配置$name..."
    chmod -R 777 /opt/wwwroot/$webdir 

    # 添加到虚拟主机
    add_vhost $port $webdir
    sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf         # 添加php-fpm支持
    sed -e "s/.*\#otherconf.*/    include \/opt\/etc\/nginx\/conf\/typecho.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf
    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "可以用phpMyaAdmin建立数据库，然后在这个站点上一步步配置网站信息"
}

######## 安装Z-Blog ########
install_zblog()
{
    # 默认配置
    filelink=$url_Zblog
    name="Zblog"
    dirname="Z-BlogPHP_1_5_1_1740_Zero"
    hookdir=$dirname
    port=91

    # 运行安装程序 
    web_installer
    echo "正在配置$name..."
    chmod -R 777 /opt/wwwroot/$webdir     # 目录权限看情况使用

    # 添加到虚拟主机
    add_vhost $port $webdir
    sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf         # 添加php-fpm支持
    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
}

######### 安装DzzOffice #########
install_dzzoffice()
{
    # 默认配置
    filelink=$url_DzzOffice
    name="DzzOffice"
    dirname="dzzoffice-master"
    port=92

    # 运行安装程序 
    web_installer
    echo "正在配置$name..."
    chmod -R 777 /opt/wwwroot/$webdir     # 目录权限看情况使用

    # 添加到虚拟主机
    add_vhost $port $webdir
    sed -e "s/.*\#php-fpm.*/    include \/opt\/etc\/nginx\/conf\/php-fpm.conf\;/g" -i /opt/etc/nginx/vhost/$webdir.conf         # 添加php-fpm支持
    onmp restart >/dev/null 2>&1
    echo "$name安装完成"
    echo "浏览器地址栏输入：$localhost:$port 即可访问"
    echo "DzzOffice应用市场中，某些应用无法自动安装的，请自行参看官网给的手动安装教程"
}

############# 添加到虚拟主机 #############
add_vhost()
{
# 写入文件
cat > "/opt/etc/nginx/vhost/$2.conf" <<-\EOF
server {
    listen 81;
    server_name localhost;
    root /opt/wwwroot/www/;
    index index.html index.htm index.php tz.php;
    #php-fpm
    #otherconf
}
EOF

sed -e "s/.*listen.*/    listen $1\;/g" -i /opt/etc/nginx/vhost/$2.conf
sed -e "s/.*\/opt\/wwwroot\/www\/.*/    root \/opt\/wwwroot\/$2\/\;/g" -i /opt/etc/nginx/vhost/$2.conf
}

############## 网站管理 ##############
web_manager()
{
    onmp stop > /dev/null 2>&1
    i=1
    for conf in /opt/etc/nginx/vhost/*;
    do
        path=$(cat $conf | awk 'NR==4' | awk '{print $2}' | sed 's/;//')
        echo "$i. $path"
        eval web_conf$i="$conf"
        eval web_file$i="$path"
        i=$((i + 1))
    done
    read -p "请选择要删除的网站：" webnum
    eval conf=\$web_conf"$webnum"
    eval file=\$web_file"$webnum"
    rm -rf "$conf"
    rm -rf "$file"
    onmp start > /dev/null 2>&1
    echo "网站已删除"
}

############## Swap交换空间 ##############
set_swap()
{
    clear
# 
cat << SWAP
----------------------------------------
|**************** SWAP ****************|
----------------------------------------
(1) 开启Swap
(2) 关闭Swap
(3) 删除Swap文件

SWAP

read -p "输入你的选择[1-3]: " input
case $input in
    1) on_swap;;
2) swapoff /opt/.swap;;
3) del_swap;;
*) echo "你输入的不是 1 ~ 3 之间的!"
break;;
esac 
}

#### 开启Swap ####
on_swap()
{
    status=$(cat /proc/swaps |  awk 'NR==2')
    if [[ -n "$status" ]]; then
        echo "Swap已启用"
    else
        if [[ ! -e "/opt/.swap" ]]; then
            echo "正在生成swap文件，请耐心等待..."
            dd if=/dev/zero of=/opt/.swap bs=1024 count=524288
            # 设置交换文件
            mkswap /opt/.swap
            chmod 0600 /opt/.swap
        fi
        # 启用交换分区
        swapon /opt/.swap
        echo "现在你可以使用free命令查看swap是否启用"
    fi
}

#### 删除Swap ####
del_swap()
{
    # 弃用交换分区
    swapoff /opt/.swap
    rm -rf /opt/.swap
}

############## 开启 Redis ###############
redis()
{
    i=1
    for conf in /opt/etc/nginx/vhost/*;
    do
        path=$(cat $conf | awk 'NR==4' | awk '{print $2}' | sed 's/;//')
        echo "$i. $path"
        eval web_file$i="$path"
        i=$((i + 1))
    done
    read -p "请选择 NextCloud 或 OwnCloud 的安装目录：" webnum
    eval file=\$web_file"$webnum"

#
echo "NC 和 OC 需要先在 web 界面配置完成后，才能使用这个选项开启 Redis"
read -p "确认安装 [Y/n]: " input
case $input in
    Y|y ) 
#
sed -e "/);/d" -i $file/config/config.php
cat >> "$file/config/config.php" <<-\EOF
'memcache.locking' => '\OC\Memcache\Redis',
'memcache.local' => '\OC\Memcache\Redis',
'redis' => array(
    'host' => '/opt/var/run/redis.sock',
    'port' => 0,
    ),
);
EOF
;;
* ) exit;;
esac 

onmp restart >/dev/null 2>&1
echo "没报错的话就是安装上了，记住以后重启之后要运行 Redis"
echo "Redis 管理命令 onmp redis start|restart|stop"
echo "我先帮你运行了"
onmp redis start

}

############## 数据库自动备份 ##############
sql_backup()
{
# 输出选项
cat << EOF
数据库自动备份
(1) 开启
(2) 关闭
(0) 退出
EOF

read -p "输入你的选择: " input
case $input in
    1) sql_backup_on;;
2) sql_backup_off;;
0) exit;;
*) echo "没有这个选项!"
exit;;
esac 
}

### 数据库自动备份开启 ###
sql_backup_on()
{
    if [[ ! -d "/opt/backup" ]]; then
        mkdir /opt/backup
    fi
    read -p "输入你的数据库用户名: " sqlusr
    read -p "输入你的数据库用户密码: " sqlpasswd

# 删除
rm -rf /opt/bin/sqlbackup

# 写入文件
cat > "/opt/bin/sqlbackup" <<-\EOF
#!/bin/sh
/opt/bin/mysqldump -uusername -puserpasswd -A > /opt/backup/sql_backup_$(date +%Y%m%d%H).sql
EOF
    
sed -e 's/username/'"$sqlusr"'/g' -i /opt/bin/sqlbackup
sed -e 's/userpasswd/'"$sqlpasswd"'/g' -i /opt/bin/sqlbackup

chmod +x /opt/bin/sqlbackup

echo "命令创建成功，你可以直接使用sqlbackup命令直接备份，也可以在路由器管理页添加定时任务 1 */3 * * * /opt/bin/sqlbackup，意思是每3 小时自动备份一次"

}

### 数据库自动备份关闭 ###
sql_backup_off()
{
    rm -rf /opt/bin/sqlbackup
    echo "如果你使用了自动定时备份，请删除配置"
}

###########################################
################# 脚本开始 #################
###########################################
start()
{
# 输出选项
cat << EOF
      ___           ___           ___           ___    
     /  /\         /__/\         /__/\         /  /\   
    /  /::\        \  \:\       |  |::\       /  /::\  
   /  /:/\:\        \  \:\      |  |:|:\     /  /:/\:\ 
  /  /:/  \:\   _____\__\:\   __|__|:|\:\   /  /:/~/:/ 
 /__/:/ \__\:\ /__/::::::::\ /__/::::| \:\ /__/:/ /:/  
 \  \:\ /  /:/ \  \:\~~\~~\/ \  \:\~~\__\/ \  \:\/:/   
  \  \:\  /:/   \  \:\  ~~~   \  \:\        \  \::/    
   \  \:\/:/     \  \:\        \  \:\        \  \:\    
    \  \::/       \  \:\        \  \:\        \  \:\   
     \__\/         \__\/         \__\/         \__\/   

=======================================================

(1) 安装ONMP
(2) 卸载ONMP
(3) 设置数据库密码
(4) 重置数据库
(5) 数据库自动备份
(6) 全部重置（会删除网站目录，请注意备份）
(7) 安装网站程序
(8) 网站管理
(9) 开启Swap
(10) 开启 Redis
(0) 退出

EOF

read -p "输入你的选择[0-9]: " input
case $input in
    1) install_onmp_ipk;;
2) remove_onmp;;
3) set_passwd;;
4) init_sql;;
5) sql_backup;;
6) init_onmp;;
7) install_website;;
8) web_manager;;
9) set_swap;;
10) redis;;
0) exit;;
*) echo "你输入的不是 0 ~ 8 之间的!"
exit;;
esac 
}

re_sh="renewsh"

if [ "$1" == "$re_sh" ]; then
    set_onmp_sh
    exit;
fi  

start
