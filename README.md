## termite  
  
Termite is a minimal VTE-based terminal emulator  
  
requires:    
apt: source: https://github.com/thestinger/termite#dependencies  
yum: source: https://github.com/thestinger/termite#dependencies  
pacman: ```pacman -S termite```  
  

Automatic install/update:
```
bash -c "$(curl -LSs https://github.com/dfmgr/termite/raw/master/install.sh)"
```
Manual install:
```
mv -fv "$HOME/.config/termite" "$HOME/.config/termite.bak"
git clone https://github.com/dfmgr/termite "$HOME/.config/termite"
```
  
  
<p align=center>
  <a href="https://wiki.archlinux.org/index.php/termite" target="_blank">termite wiki</a>  |  
  <a href="https://github.com/thestinger/termite" target="_blank">termite site</a>
</p>  
