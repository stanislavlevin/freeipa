#
# Copyright (C) 2018  FreeIPA Contributors see COPYING for license
#
from importlib import import_module
from ipapython.ntpmethods import TIME_SERVICE


def detect_ntp_daemon():
    ntp_libs = {
        'chrony': ['chronylib', 'Chrony'],
        'ntpd': ['ntpdlib', 'NTPD'],
        'openntpd': ['ontpdlib', 'OpenNTPD'],
    }

    clintplib = import_module("ipaclient.install.clintplib")

    try:
        servntplib = import_module("ipaserver.install.servntplib")
    except Exception:
        servntplib = None

    servts = None
    if servntplib:
        servts = getattr(servntplib, ntp_libs[TIME_SERVICE][1] + 'Server')

    clits = getattr(clintplib, ntp_libs[TIME_SERVICE][1] + 'Client')

    return servts, clits


NTPSERVER, NTPCLIENT = detect_ntp_daemon()


def sync_time_server(fstore, sstore, ntp_servers, ntp_pool):
    cl = NTPSERVER()

    cl.fstore = fstore
    cl.sstore = sstore
    cl.ntp_servers = ntp_servers
    cl.ntp_pool = ntp_pool

    try:
        cl.sync_time()
        return True
    except Exception:
        return False


def sync_time_client(fstore, statestore, cli_domain, ntp_servers, ntp_pool):
    cl = NTPCLIENT()

    cl.fstore = fstore
    cl.statestore = statestore
    cl.cli_domain = cli_domain
    cl.ntp_servers = ntp_servers
    cl.ntp_pool = ntp_pool

    return cl.sync_time()


def uninstall_server(fstore, sstore):
    cl = NTPSERVER()

    cl.sstore = sstore
    cl.fstore = fstore

    cl.uninstall()


def uninstall_client(fstore, sstore):
    cl = NTPCLIENT()

    cl.statestore = sstore
    cl.fstore = fstore

    cl.uninstall()