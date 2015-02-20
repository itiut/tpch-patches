tpch-patches
====

Patches to run TPC-H benchmark on PostgreSQL and MySQL.


Supported version
----
- TPC-H 2.17.0
- DBGen 2.17.0


Usage
----

### Install
```console
$ PREFIX=$HOME ./install.sh <postgres|mysql>
```

`install.sh` performs:
- Download and unzip DBGen in `$PREFIX/src`
- Apply patches to and build `dbgen` and `qgen`
- Copy `dbgen`, `qgen` and other required files into `$PREFIX/share/dbgen`
- Install wrapper scripts of `dbgen` and `qgen` with the same name into `$PREFIX/bin`

The default value of `$PREFIX` is assigned to `$HOME`.

### Uninstall
```console
$ PREFIX=$HOME ./uninstall.sh
```

`uninstall.sh` performs:
- Remove `$PREFIX/bin/{dbgen,qgen}`
- Remove `$PREFIX/share/dbgen`
