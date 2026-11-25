import { BlockList, isIP } from 'node:net';
import { Fault } from './http.mjs';
const reserved = new BlockList();
for (const [ip, prefix] of [['0.0.0.0',8], ['10.0.0.0',8], ['100.64.0.0',10], ['127.0.0.0',8], ['169.254.0.0',16], ['172.16.0.0',12], ['192.0.0.0',24], ['192.0.2.0',24], ['192.88.99.0',24], ['192.168.0.0',16], ['198.18.0.0',15], ['198.51.100.0',24], ['203.0.113.0',24], ['224.0.0.0',3]]) reserved.addSubnet(ip,prefix,'ipv4');
const special6 = new BlockList();
for (const [ip, prefix] of [['2001::',23], ['2001:db8::',32], ['2002::',16], ['3fff::',20]]) special6.addSubnet(ip,prefix,'ipv6');
export function publicAddress(address) {
  if (isIP(address) === 4) return !reserved.check(address,'ipv4');
  // Only currently allocated global unicast; mapped/compatible, NAT64 and all
  // local, link-local, multicast, documentation and transition ranges denied.
  return isIP(address) === 6 && /^[23]/.test(address) && !special6.check(address,'ipv6');
}
export function parseServer(value) {
  if (typeof value !== 'string' || !value || value.length > 2048 || value !== value.trim() || /[\\%?#\s]/.test(value) || /(?:^|\/)\.{1,2}(?:\/|$)/.test(value)) throw new Fault(400,'invalid_server_url');
  let u; try { u = new URL(value); } catch { throw new Fault(400,'invalid_server_url'); }
  const authority=/^https?:\/\/(\[[0-9a-fA-F:]+\]|[A-Za-z0-9.-]+)(?::[0-9]+)?(?:\/|$)/.exec(value);
  if (!authority || /[\x00-\x20\x7f]/.test(value) || authority[1].endsWith('.') ||
      (isIP(u.hostname.replace(/^\[|\]$/g,'')) && authority[1].toLowerCase() !== u.hostname)) throw new Fault(400,'invalid_server_url');
  if (!['https:','http:'].includes(u.protocol) || u.username || u.password || !/^\/(?:[A-Za-z0-9_-]+\/)*[A-Za-z0-9_-]*\/*$/.test(u.pathname)) throw new Fault(400,'invalid_server_url');
  u.pathname = u.pathname.replace(/\/+$/, '') || '/';
  return u;
}
export function trustedServer(u, options) {
  const configured = [...(options.allowedUpstreams ?? []), ...(options.upstream ? [options.upstream] : [])];
  return configured.some(value => {
    const allowed = parseServer(value);
    // Operator policy grants an exact origin (scheme + host + port), not a
    // suffix, wildcard or address returned by untrusted DNS.
    return allowed.origin === u.origin;
  });
}
export function selectUpstream(value, options) {
  const u = parseServer(value);
  if (u.protocol !== 'https:' && !(options.allowHttp === true && trustedServer(u, options))) throw new Fault(400,'server_https_required');
  const host = u.hostname.replace(/^\[|\]$/g,'');
  if (isIP(host) && !publicAddress(host) && !trustedServer(u, options)) throw new Fault(400,'server_destination_denied');
  return u;
}
