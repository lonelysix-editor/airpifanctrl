# AirPi Fan Control for OpenWrt

AirPi Fan Control contains two OpenWrt packages:

- `airpi-gpio-fan`: kernel package for the GPIO PWM fan driver. Put this directory under `package/kernel/` in the OpenWrt source tree.
- `luci-app-airpifanctrl`: LuCI web UI and control scripts. Keep this package in a normal feed or package directory and select it from `make menuconfig`.

## Repository

```sh
git clone https://github.com/lonelysix-editor/airpifanctrl.git
```

## OpenWrt Build Usage

Copy the kernel package into the OpenWrt tree:

```sh
cp -r airpifanctrl/airpi-gpio-fan openwrt/package/kernel/
```

Use the LuCI package as a feed package, for example:

```sh
echo "src-git airpifanctrl https://github.com/lonelysix-editor/airpifanctrl.git" >> openwrt/feeds.conf.default
cd openwrt
./scripts/feeds update airpifanctrl
./scripts/feeds install luci-app-airpifanctrl
```

Then run:

```sh
make menuconfig
```

Select:

- `Kernel modules -> Other modules -> kmod-airpi-gpio-fan`
- `LuCI -> Applications -> luci-app-airpifanctrl`

## Notes

The current driver uses GPIO `540` and exposes fan speed through the platform PWM fan path used by the bundled LuCI scripts. Adjust the GPIO number or sysfs path in the source if your target board differs.

## License

The LuCI package includes an Apache-2.0 license file. The kernel module declares GPL in source.
