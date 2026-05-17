
mkdir -p /home/gun-gun-priatna/Projects/demo-frontend/{releases,shared}


mkdir -p /home/gun-gun-priatna/Projects/demo-frontend/shared/storage
mkdir -p /home/gun-gun-priatna/Projects/demo-frontend/shared/bootstrap/cache




sudo chown -R gun-gun-priatna:www-data /home/gun-gun-priatna/Projects/demo-frontend
sudo find /home/gun-gun-priatna/Projects/demo-frontend -type d -exec chmod 775 {} \;
sudo find /home/gun-gun-priatna/Projects/demo-frontend -type f -exec chmod 664 {} \;
sudo find /home/gun-gun-priatna/Projects/demo-frontend -type d -exec chmod g+s {} \;

chmod -R 775 /home/gun-gun-priatna/Projects/demo-frontend/shared/storage
chmod -R 775 /home/gun-gun-priatna/Projects/demo-frontend/shared/bootstrap/cache




---
extract

cd ~/2026-05-09

TIMESTAMP=$(date +%Y%m%d%H%M%S)
mkdir -p /home/gun-gun-priatna/Projects/demo-frontend/releases/$TIMESTAMP

tar -xzf frontend_source_2026-05-09.tar.gz \
-C /home/gun-gun-priatna/Projects/demo-frontend/releases/$TIMESTAMP



cd /home/gun-gun-priatna/Projects/demo-frontend/releases/$TIMESTAMP

mv qadrlabs-frontend/* .
mv qadrlabs-frontend/.* . 2>/dev/null || true

rmdir qadrlabs-frontend

---


copy .env

cp .env /home/gun-gun-priatna/Projects/demo-frontend/shared/.env
nano /home/gun-gun-priatna/Projects/demo-frontend/shared/.env


---
setup symlink

rm -rf storage
ln -sfn \
/home/gun-gun-priatna/Projects/demo-frontend/shared/storage \
storage
ln -sfn \
/home/gun-gun-priatna/Projects/demo-frontend/shared/.env \
.env

---
public storage:

rm -rf public/storage
ln -sfn \
/home/gun-gun-priatna/Projects/demo-frontend/shared/storage/app/public \
public/storage


----
atomic current link

ln -sfn \
/home/gun-gun-priatna/Projects/demo-frontend/releases/$TIMESTAMP \
/home/gun-gun-priatna/Projects/demo-frontend/current


---
setup permission
sudo chown -R gun-gun-priatna:www-data \
/home/gun-gun-priatna/Projects/demo-frontend
find /home/gun-gun-priatna/Projects/demo-frontend \
-type d -exec chmod 775 {} \;
find /home/gun-gun-priatna/Projects/demo-frontend \
-type f -exec chmod 664 {} \;
find /home/gun-gun-priatna/Projects/demo-frontend \
-type d -exec chmod g+s {} \;


---
sudo nano /etc/nginx/sites-available/demo-frontend.qadrlabs.com


---
enable

sudo ln -s \
/etc/nginx/sites-available/demo-frontend.qadrlabs.com \
/etc/nginx/sites-enabled/


---
sudo certbot --nginx -d demo-frontend.qadrlabs.com www.demo-frontend.qadrlabs.com


---

fix error permission pada saat setup first rilis

```
In PackageManifest.php line 179:
                                                                               
  The /home/gun-gun-priatna/Projects/demo-frontend/releases/20260509204433/bo  
  otstrap/cache directory must be present and writable.                        
                                                                               

Script @php artisan package:discover --ansi handling the post-autoload-dump event returned with error code 1

```

cd /home/gun-gun-priatna/Projects/demo-frontend/releases/20260509204433
mkdir -p bootstrap/cache
mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/logs

chmod -R 775 bootstrap/cache
chmod -R 775 storage
chmod -R ug+rwx bootstrap/cache storage

composer install --no-dev --optimize-autoloader


---

nano ~/deploy-demo-frontend.sh

chmod +x ~/deploy-demo-frontend.sh

~/deploy-demo-frontend.sh



---
sudo nginx -t

sudo systemctl reload nginx
sudo systemctl restart php8.5-fpm




---



sudo nano /etc/nginx/sites-available/app.qadrlabs.com
---
enable

sudo ln -s \
/etc/nginx/sites-available/app.qadrlabs.com \
/etc/nginx/sites-enabled/



sudo certbot --nginx -d app.qadrlabs.com






---
sudo nano /etc/nginx/sites-available/qadrlabs.com
---
enable

sudo ln -s \
/etc/nginx/sites-available/qadrlabs.com \
/etc/nginx/sites-enabled/



sudo certbot --nginx -d qadrlabs.com



---
sudo nano /etc/supervisor/conf.d/qadrlabs-frontend-worker.conf


---
start worker

sudo supervisorctl start qadrlabs-frontend-worker:*


Cmnd_Alias SUPERVISOR_RESTART = /usr/bin/supervisorctl restart qadrlabs-frontend-worker:*
gun-gun-priatna ALL=(root) NOPASSWD: SUPERVISOR_RESTART




Cmnd_Alias PHPFPM_RELOAD = /usr/bin/systemctl reload php8.5-fpm

Cmnd_Alias SUPERVISOR_RESTART = /usr/bin/supervisorctl restart qadrlabs-frontend-worker:qadrlabs-frontend-worker_00, /usr/bin/supervisorctl restart qadrlabs-frontend-worker:qadrlabs-frontend-worker_01

gun-gun-priatna ALL=(root) NOPASSWD: PHPFPM_RELOAD
gun-gun-priatna ALL=(root) NOPASSWD: SUPERVISOR_RESTART

gun-gun-priatna ALL=(root) NOPASSWD: /usr/bin/supervisorctl restart qadrlabs-frontend-worker:qadrlabs-frontend-worker_01