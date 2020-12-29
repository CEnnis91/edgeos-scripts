# firstboot.d

Any executable script in this directory will executed **after** a firmware upgrade. `ubnt-rcS.sh` calls run-parts on this directory. This is determined from the existance of the `/etc/ubnt/firstboot` file.
