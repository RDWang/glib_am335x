#!/bin/sh 
#交叉编译glib的脚本

#定义变量
PWD=`pwd`
ROOT_DIR=$PWD
TARGET="target"

#建立编译目录
if test -e $TARGET;then
    rm -fr $TARGET
fi
mkdir $TARGET

#编译zlib
cd zlib
git reset --hard
./configure --prefix=${ROOT_DIR}/${TARGET}

#在make之前需要将刚刚生成的Makefile文件中的所有gcc、ar、ranlib替换成本地的交叉编译工具，
#我使用的交叉编译工具前缀是arm-linux-gnueabihf-，将上面3个工具加前缀修改保存即可
#修改为自动编辑
sed -i 's/\<gcc\>/arm-linux-gnueabihf-gcc/g' Makefile
sed -i 's/\<ar\>/arm-linux-gnueabihf-ar/g' Makefile
sed -i 's/\<ranlib\>/arm-linux-gnueabihf-ranlib/g' Makefile
make
make install

cd ${ROOT_DIR}

#编译libffi
cd libffi
#由于不同的版本对交叉编译工具的要求不同，我的本地交叉工具版本是2013年的，于是考虑使用
#2013年左右的libffi版本，选择使用v3.1
git checkout v3.1 -b v3.1
./autogen.sh
./configure --host=arm-linux-gnueabihf --prefix=${ROOT_DIR}/${TARGET}
make
make install

cd ${ROOT_DIR}

#将libffi和zlib编译目录添加到pkg搜索目录
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${ROOT_DIR}/${TARGET}/lib/pkgconfig

#编译glib库
cd glib
#同样将glib版本切换到与交叉编译器版本附件的版本
git checkout v2.39.90 -b v2.39.90
./autogen.sh
./configure --host=arm-linux-gnueabihf --prefix=${ROOT_DIR}/${TARGET} PKG_CONFIG_PATH=${ROOT_DIR}/${TARGET}/lib/pkgconfig  glib_cv_stack_grows=no glib_cv_uscore=yes ac_cv_func_posix_getpwuid_r=yes ac_cv_func_posix_getgrgid_r=yes 
make
make install

cd ${ROOT_DIR}

#拷贝并打包glib动态库文件
if test -e "target_arm";then
    rm -fr ./target_arm
fi
mkdir target_arm
cd target_arm
cp -afr ${ROOT_DIR}/${TARGET}/lib/libglib-2.0* ./ 
rm -fr libglib-2.0.la



