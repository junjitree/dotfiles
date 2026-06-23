function bootwin --description "Reboot into Windows"
    sudo efibootmgr --bootnext 0000 && sudo reboot
end
