# luci-app-airpifanctrl

LuCI web UI and control scripts for AirPi fan control.

This package depends on `kmod-airpi-gpio-fan`. Build the kernel module package from `airpi-gpio-fan` first, or place that package under `package/kernel/` before selecting this LuCI app.

## Feed Usage

```sh
echo "src-git airpifanctrl https://github.com/lonelysix-editor/airpifanctrl.git" >> feeds.conf.default
./scripts/feeds update airpifanctrl
./scripts/feeds install luci-app-airpifanctrl
```

Then enable `luci-app-airpifanctrl` in `make menuconfig`.
