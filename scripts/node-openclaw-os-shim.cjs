/**
 * OpenShell/Landlock e políticas seccomp podem fazer falhar os.getifaddrs() em
 * os.networkInterfaces() (uv_interface_addresses). Bibliotecas como @homebridge/ciao
 * quebram ao subir o gateway. Este módulo carrega antes do entrypoint e devolve uma
 * lista sintética quando a chamada real falha.
 */
'use strict';

const os = require('node:os');

const orig = os.networkInterfaces.bind(os);

function syntheticInterfaces() {
  const fakeIp = process.env.OPENCLAW_FAKE_INTERFACE_ADDRESS || '10.255.255.254';
  const fakeName = process.env.OPENCLAW_FAKE_INTERFACE_NAME || 'eth0';
  return {
    lo: [
      {
        address: '127.0.0.1',
        netmask: '255.0.0.0',
        family: 4,
        mac: '00:00:00:00:00:00',
        internal: true,
        cidr: '127.0.0.1/8',
      },
      {
        address: '::1',
        netmask: 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
        family: 6,
        mac: '00:00:00:00:00:00',
        internal: true,
        scopeid: 0,
        cidr: '::1/128',
      },
    ],
    [fakeName]: [
      {
        address: fakeIp,
        netmask: '255.255.255.255',
        family: 4,
        mac: '02:00:00:00:00:01',
        internal: false,
        cidr: `${fakeIp}/32`,
      },
    ],
  };
}

function networkInterfaces() {
  try {
    const result = orig();
    if (result && typeof result === 'object' && Object.keys(result).length > 0) {
      return result;
    }
  } catch {
    /* cair no sintético */
  }
  return syntheticInterfaces();
}

Object.defineProperty(os, 'networkInterfaces', {
  value: networkInterfaces,
  configurable: true,
  enumerable: true,
  writable: true,
});
