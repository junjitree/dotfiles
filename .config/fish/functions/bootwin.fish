function bootwin --description "Reboot into Windows"
    if contains -- --remote $argv
        ssh -t junji@junji-pc-arch "sudo efibootmgr --bootnext 0000 && sudo reboot"
        return
    end
    if test (cat /etc/hostname) != junji-pc
        echo "bootwin: only runs on junji-pc (use --remote)"
        return 1
    end
    sudo efibootmgr --bootnext 0000 && sudo reboot
end
