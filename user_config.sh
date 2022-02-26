# LFS User shell configuration file.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PATH=/usr/bin
if [ ! -L /bin ]
then
    PATH=/bin:$PATH
fi
PATH=$LFS/tools/bin:$PATH

CONFIG_SITE=$LFS/usr/share/config.site
LC_ALL=POSIX

export LC_ALL PATH CONFIG_SITE
