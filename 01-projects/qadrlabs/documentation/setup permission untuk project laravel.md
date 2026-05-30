
```

# Setup proper group ownership
sudo chgrp -R www-data storage/ bootstrap/cache/
sudo find storage/ -type d -exec chmod g+s {} \;
sudo find bootstrap/cache/ -type d -exec chmod g+s {} \;
sudo find storage/ -type d -exec chmod 775 {} \;
sudo find bootstrap/cache/ -type d -exec chmod 775 {} \;

# Pastikan user dalam group www-data
sudo usermod -a -G www-data gun-gun-priatna


sudo setfacl -R -m g:www-data:rwx storage/framework/cache/
sudo setfacl -R -d -m g:www-data:rwx storage/framework/cache/
sudo setfacl -R -m u:gun-gun-priatna:rwx storage/framework/cache/
sudo setfacl -R -d -m u:gun-gun-priatna:rwx storage/framework/cache/

# Verify
getfacl storage/framework/cache/
```