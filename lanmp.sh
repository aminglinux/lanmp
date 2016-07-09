#!/bin/bash
## written by aming.
## 2015-06-24.

#######Begin########
echo "It will install lamp or lnmp."
sleep 1
##check last command is OK or not.
check_ok() {
if [ $? != 0 ]
then
    echo "Error, Check the error log."
    exit 1
fi
}
##get the archive of the system,i686 or x86_64.
ar=`arch`
##close seliux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
selinux_s=`getenforce`
if [ $selinux_s == "enforcing" ]
then
    setenforce 0
fi
##close iptables
iptables-save > /etc/sysconfig/iptables_`date +%s`
iptables -F
service iptables save

##if the packge installed ,then omit.
myum() {
if ! rpm -qa|grep -q "^$1"
then
    yum install -y $1
    check_ok
else
    echo $1 already installed.
fi
}

## install some packges.
for p in gcc wget perl perl-devel libaio libaio-devel pcre-devel zlib-devel
do
    myum $p
done

##install epel.
if rpm -qa epel-release >/dev/null
then
    rpm -e epel-release
fi
if ls /etc/yum.repos.d/epel-6.repo* >/dev/null 2>&1
then
    rm -f /etc/yum.repos.d/epel-6.repo*
fi
wget -P /etc/yum.repos.d/ http://mirrors.aliyun.com/repo/epel-6.repo


##function of installing mysqld.
install_mysqld() {
    case $mysql_v in
        5.1)
            cd /usr/local/src
            [ -f mysql-5.1.72-linux-$ar-glibc23.tar.gz ] || wget http://mirrors.sohu.com/mysql/MySQL-5.1/mysql-5.1.72-linux-$ar-glibc23.tar.gz
            tar zxf mysql-5.1.72-linux-$ar-glibc23.tar.gz
            check_ok
            [ -d /usr/local/mysql ] && /bin/mv /usr/local/mysql /usr/local/mysql_`date +%s`
            mv mysql-5.1.72-linux-$ar-glibc23 /usr/local/mysql
            check_ok
            if ! grep '^mysql:' /etc/passwd
            then
                useradd -M mysql -s /sbin/nologin
                check_ok
            fi
            myum compat-libstdc++-33
            [ -d /data/mysql ] && /bin/mv /data/mysql /data/mysql_`date +%s`
            mkdir -p /data/mysql
            chown -R mysql:mysql /data/mysql
            cd /usr/local/mysql
            ./scripts/mysql_install_db --user=mysql --datadir=/data/mysql
            check_ok
            /bin/cp support-files/my-huge.cnf /etc/my.cnf
            check_ok
            sed -i '/^\[mysqld\]$/a\datadir = /data/mysql' /etc/my.cnf
            /bin/cp support-files/mysql.server /etc/init.d/mysqld
            sed -i 's#^datadir=#datadir=/data/mysql#' /etc/init.d/mysqld
            chmod 755 /etc/init.d/mysqld
            chkconfig --add mysqld
            chkconfig mysqld on
            service mysqld start
            check_ok
            break
            ;;
        5.6)
            cd /usr/local/src
            [ -f mysql-5.6.26-linux-glibc2.5-$ar.tar.gz ] || wget http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.26-linux-glibc2.5-$ar.tar.gz
            tar zxf mysql-5.6.26-linux-glibc2.5-$ar.tar.gz
            check_ok
            [ -d /usr/local/mysql ] && /bin/mv /usr/local/mysql /usr/local/mysql_bak
            mv mysql-5.6.26-linux-glibc2.5-$ar /usr/local/mysql
            if ! grep '^mysql:' /etc/passwd
            then
                useradd -M mysql -s /sbin/nologin
            fi
            myum compat-libstdc++-33
            [ -d /data/mysql ] && /bin/mv /data/mysql /data/mysql_bak
            mkdir -p /data/mysql
            chown -R mysql:mysql /data/mysql
            cd /usr/local/mysql
            ./scripts/mysql_install_db --user=mysql --datadir=/data/mysql
            check_ok
            /bin/cp support-files/my-default.cnf /etc/my.cnf
            check_ok
            sed -i '/^\[mysqld\]$/a\datadir = /data/mysql' /etc/my.cnf
            /bin/cp support-files/mysql.server /etc/init.d/mysqld
            sed -i 's#^datadir=#datadir=/data/mysql#' /etc/init.d/mysqld
            chmod 755 /etc/init.d/mysqld
            chkconfig --add mysqld
            chkconfig mysqld on
            service mysqld start
            check_ok
            break
            ;;

         *)
            echo "only 1(5.1) or 2(5.6)"
            exit 1
            ;;
    esac
}

##function of install httpd.
install_httpd() {
echo "Install apache version 2.2."
cd /usr/local/src
[ -f httpd-2.2.16.tar.gz ] || wget  http://syslab.comsenz.com/downloads/linux/httpd-2.2.16.tar.gz
tar zxf  httpd-2.2.16.tar.gz && cd httpd-2.2.16
check_ok
./configure \
--prefix=/usr/local/apache2 \
--with-included-apr \
--enable-so \
--enable-deflate=shared \
--enable-expires=shared \
--enable-rewrite=shared \
--with-pcre
check_ok
make && make install
check_ok
}

##function of install lamp's php.
install_php() {
echo -e "Install php.\nPlease chose the version of php."
    case $php_v in
        5.4)
            cd /usr/local/src/
            [ -f php-5.4.45.tar.bz2 ] || wget 'http://cn2.php.net/get/php-5.4.45.tar.bz2/from/this/mirror' -O php-5.4.45.tar.bz2
            tar jxf php-5.4.45.tar.bz2 && cd php-5.4.45

            for p in openssl-devel bzip2-devel \
            libxml2-devel curl-devel libpng-devel \
            libjpeg-devel freetype-devel libmcrypt-devel\
            libtool-ltdl-devel perl-devel
            do
                myum $p
            done

            check_ok
            ./configure \
            --prefix=/usr/local/php \
            --with-apxs2=/usr/local/apache2/bin/apxs \
            --with-config-file-path=/usr/local/php/etc  \
            --with-mysql=/usr/local/mysql \
            --with-libxml-dir \
            --with-gd \
            --with-jpeg-dir \
            --with-png-dir \
            --with-freetype-dir \
            --with-iconv-dir \
            --with-zlib-dir \
            --with-bz2 \
            --with-openssl \
            --with-mcrypt \
            --enable-soap \
            --enable-gd-native-ttf \
            --enable-mbstring \
            --enable-sockets \
            --enable-exif \
            --disable-ipv6
            check_ok
            make && make install
            check_ok
            [ -f /usr/local/php/etc/php.ini ] || /bin/cp php.ini-production  /usr/local/php/etc/php.ini
            break
            ;;
        5.6)
            cd /usr/local/src/
            [ -f php-5.6.6.tar.gz ] || wget http://mirrors.sohu.com/php/php-5.6.6.tar.gz
            tar zxf php-5.6.6.tar.gz &&   cd php-5.6.6
            for p in openssl-devel bzip2-devel \
            libxml2-devel curl-devel libpng-devel \
            libjpeg-devel freetype-devel libmcrypt-devel\
            libtool-ltdl-devel perl-devel
            do
                myum $p
            done

            ./configure \
            --prefix=/usr/local/php \
            --with-apxs2=/usr/local/apache2/bin/apxs \
            --with-config-file-path=/usr/local/php/etc  \
            --with-mysql=/usr/local/mysql \
            --with-libxml-dir \
            --with-gd \
            --with-jpeg-dir \
            --with-png-dir \
            --with-freetype-dir \
            --with-iconv-dir \
            --with-zlib-dir \
            --with-bz2 \
            --with-openssl \
            --with-mcrypt \
            --enable-soap \
            --enable-gd-native-ttf \
            --enable-mbstring \
            --enable-sockets \
            --enable-exif \
            --disable-ipv6
            check_ok
            make && make install
            check_ok
            [ -f /usr/local/php/etc/php.ini ] || /bin/cp php.ini-production  /usr/local/php/etc/php.ini
            break
            ;;

        *)
            echo "only 1(5.4) or 2(5.6)"
            ;;
    esac
}

##function of apache and php configue.
join_apa_php() {
sed -i '/AddType .*.gz .tgz$/a\AddType application\/x-httpd-php .php' /usr/local/apache2/conf/httpd.conf
check_ok
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html index.htm/' /usr/local/apache2/conf/httpd.conf
check_ok
cat > /usr/local/apache2/htdocs/index.php <<EOF
<?php
   phpinfo();
?>
EOF

if /usr/local/php/bin/php -i |grep -iq 'date.timezone => no value'
then
    sed -i '/;date.timezone =$/a\date.timezone = "Asia\/Chongqing"'  /usr/local/php/etc/php.ini
fi

/usr/local/apache2/bin/apachectl restart
check_ok
}

##function of check service is running or not, example nginx, httpd, php-fpm.
check_service() {
if [ "$1" == "phpfpm" ]
then
    s="php-fpm"
else
    s=$1
fi
n=`ps aux |grep "$s"|wc -l`
if [ $n -gt 1 ]
then
    echo "$1 service is already started."
else
    if [ -f /etc/init.d/$1 ]
    then
        /etc/init.d/$1 start
        check_ok
    else
        install_$1
    fi
fi
}

##function of install lamp
lamp() {
check_service mysqld
check_service httpd
install_php
join_apa_php
echo "LAMP done，Please use 'http://your ip/index.php' to access."
}

##function of install nginx
install_nginx() {
cd /usr/local/src
[ -f nginx-1.8.0.tar.gz ] || wget http://nginx.org/download/nginx-1.8.0.tar.gz
tar zxf nginx-1.8.0.tar.gz
cd nginx-1.8.0
myum pcre-devel
./configure --prefix=/usr/local/nginx
check_ok
make && make install
check_ok
if [ -f /etc/init.d/nginx ]
then
    /bin/mv /etc/init.d/nginx  /etc/init.d/nginx_`date +%s`
fi
curl http://www.apelearn.com/study_v2/.nginx_init  -o /etc/init.d/nginx
check_ok
chmod 755 /etc/init.d/nginx
chkconfig --add nginx
chkconfig nginx on
curl http://www.apelearn.com/study_v2/.nginx_conf -o /usr/local/nginx/conf/nginx.conf
check_ok
service nginx start
check_ok
echo -e "<?php\n    phpinfo();\n?>" > /usr/local/nginx/html/index.php
check_ok
}

##function of install php-fpm
install_phpfpm() {
echo -e "Install php.\nPlease chose the version of php."
    case $php_v in
        5.4)
            cd /usr/local/src/
            [ -f php-5.4.45.tar.bz2 ] || wget 'http://cn2.php.net/get/php-5.4.45.tar.bz2/from/this/mirror' -O php-5.4.45.tar.bz2
            tar jxf php-5.4.45.tar.bz2 && cd php-5.4.45
            for p in  openssl-devel bzip2-devel \
            libxml2-devel curl-devel libpng-devel \
            libjpeg-devel freetype-devel libmcrypt-devel\
            libtool-ltdl-devel perl-devel
            do
                myum $p
            done
            if ! grep -q '^php-fpm:' /etc/passwd
            then
                useradd -M -s /sbin/nologin php-fpm
                check_ok
            fi
            ./configure \
            --prefix=/usr/local/php-fpm \
            --with-config-file-path=/usr/local/php-fpm/etc \
            --enable-fpm \
            --with-fpm-user=php-fpm \
            --with-fpm-group=php-fpm \
            --with-mysql=/usr/local/mysql \
            --with-mysql-sock=/tmp/mysql.sock \
            --with-libxml-dir \
            --with-gd \
            --with-jpeg-dir \
            --with-png-dir \
            --with-freetype-dir \
            --with-iconv-dir \
            --with-zlib-dir \
            --with-mcrypt \
            --enable-soap \
            --enable-gd-native-ttf \
            --enable-ftp \
            --enable-mbstring \
            --enable-exif \
            --enable-zend-multibyte \
            --disable-ipv6 \
            --with-pear \
            --with-curl \
            --with-openssl
            check_ok
            make && make install
            check_ok
            [ -f /usr/local/php-fpm/etc/php.ini ] || /bin/cp php.ini-production  /usr/local/php-fpm/etc/php.ini
            if /usr/local/php-fpm/bin/php -i |grep -iq 'date.timezone => no value'
            then
                sed -i '/;date.timezone =$/a\date.timezone = "Asia\/Chongqing"'  /usr/local/php-fpm/etc/php.ini
                check_ok
            fi
            [ -f /usr/local/php-fpm/etc/php-fpm.conf ] || curl http://www.apelearn.com/study_v2/.phpfpm_conf -o /usr/local/php-fpm/etc/php-fpm.conf
            [ -f /etc/init.d/phpfpm ] || /bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/phpfpm
            chmod 755 /etc/init.d/phpfpm
            chkconfig phpfpm on
            service phpfpm start
            check_ok
            break
            ;;
        5.6)
            cd /usr/local/src/
            [ -f php-5.6.6.tar.gz ] || wget http://mirrors.sohu.com/php/php-5.6.6.tar.gz

            tar zxf php-5.6.6.tar.gz &&   cd php-5.6.6
            for p in  openssl-devel bzip2-devel \
            libxml2-devel curl-devel libpng-devel \
            libjpeg-devel freetype-devel libmcrypt-devel\
            libtool-ltdl-devel perl-devel
            do
                myum $p
            done

            if ! grep -q '^php-fpm:' /etc/passwd
            then
                useradd -M -s /sbin/nologin php-fpm
            fi
            check_ok
            ./configure \
            --prefix=/usr/local/php-fpm \
            --with-config-file-path=/usr/local/php-fpm/etc \
            --enable-fpm \
            --with-fpm-user=php-fpm \
            --with-fpm-group=php-fpm \
            --with-mysql=/usr/local/mysql \
            --with-mysql-sock=/tmp/mysql.sock \
            --with-libxml-dir \
            --with-gd \
            --with-jpeg-dir \
            --with-png-dir \
            --with-freetype-dir \
            --with-iconv-dir \
            --with-zlib-dir \
            --with-mcrypt \
            --enable-soap \
            --enable-gd-native-ttf \
            --enable-ftp \
            --enable-mbstring \
            --enable-exif \
            --disable-ipv6 \
            --with-pear \
            --with-curl \
            --with-openssl
            check_ok
            make && make install
            check_ok
            [ -f /usr/local/php-fpm/etc/php.ini ] || /bin/cp php.ini-production  /usr/local/php-fpm/etc/php.ini
            if /usr/local/php-fpm/bin/php -i |grep -iq 'date.timezone => no value'
            then
                sed -i '/;date.timezone =$/a\date.timezone = "Asia\/Chongqing"'  /usr/local/php-fpm/etc/php.ini
                check_ok
            fi
            [ -f /usr/local/php-fpm/etc/php-fpm.conf ] || curl http://www.apelearn.com/study_v2/.phpfpm_conf -o /usr/local/php-fpm/etc/php-fpm.conf
            check_ok
            [ -f /etc/init.d/phpfpm ] || /bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/phpfpm
            chmod 755 /etc/init.d/phpfpm
            chkconfig phpfpm on
            service phpfpm start
            check_ok
            break
            ;;

        *)
            echo 'only 1(5.4) or 2(5.6)'
            ;;
    esac
}

##function of install lnmp
lnmp() {
check_service mysqld
check_service nginx
check_service phpfpm
echo "The lnmp done, Please use 'http://your ip/index.php' to access."
}

read -p "Please chose which type env you install, (lamp|lnmp)? " t
case $t in
    lamp)
        read -p "Please chose the version of mysql. (5.1|5.6)" mysql_v
        read -p "Please chose the version of php. (5.4|5.6)" php_v
        lamp
        ;;
    lnmp)
        read -p "Please chose the version of mysql. (5.1|5.6)" mysql_v
        read -p "Please chose the version of php. (5.4|5.6)" php_v
        lnmp
        ;;
    *)
        echo "Only 'lamp' or 'lnmp' your can input."
        ;;
esac
##111111
##########end##############
