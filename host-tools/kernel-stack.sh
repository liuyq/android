#!/bin/bash -e

stack="
[    1.858189] [<ffffff800808c314>] dump_backtrace+0x0/0x218
[    1.858206] [<ffffff800808c308>] show_stack+0x20/0x2c
[    1.858223] [<ffffff80085506b0>] dump_stack+0xdc/0x12c
[    1.858243] [<ffffff8008b1b36c>] xfrm_state_init+0x58/0xfc
[    1.858258] [<ffffff8008b155d0>] xfrm_net_init+0x40/0x220
[    1.858276] [<ffffff8008a1fd2c>] ops_init+0x100/0x14c
[    1.858292] [<ffffff8008a1f5e0>] register_pernet_operations+0xdc/0x230
[    1.858307] [<ffffff8008a1f4e8>] register_pernet_subsys+0x34/0x50
[    1.858326] [<ffffff80091a3a4c>] xfrm_init+0x14/0x28
[    1.858341] [<ffffff800919f834>] ip_rt_init+0x18c/0x218
[    1.858355] [<ffffff800919fa70>] ip_init+0xc/0x1c
[    1.858370] [<ffffff80091a08c4>] inet_init+0x414/0x4d8
[    1.858386] [<ffffff8008083c6c>] do_one_initcall+0xf4/0x19c
[    1.858404] [<ffffff8009140ed4>] kernel_init_freeable+0x1c0/0x254
[    1.858422] [<ffffff8008cb9420>] kernel_init+0x14/0x208
[    1.858437] [<ffffff8008083ab0>] ret_from_fork+0x10/0x20
"
f_stack="/tmp/stack.txt"
#echo $stack >$f_stack
cmd_addr2line="prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-addr2line"
f_vmlinux="out/target/product/hikey/obj/kernel-4.4/vmlinux"
while read line; do
    addr=$(echo $line|sed 's/^.*\[<//')
    addr=$(echo ${addr}|sed 's/>\].*$//')
    addr_info=$(${cmd_addr2line} -e ${f_vmlinux} ${addr})
    addr_info=$(echo ${addr_info}|sed 's/:/ +/')
    echo "$line  ${addr_info}"
done < $f_stack
