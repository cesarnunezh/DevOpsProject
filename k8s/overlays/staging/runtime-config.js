window.__APP_CONFIG__ = (() => {
  const host = window.location.hostname || "localhost";
  const isIngressHost = host.endsWith(".devops.local");

  return {
    API_ORDERS: isIngressHost ? "/orders" : `http://${host}:30050`,
    API_PRODUCTS: isIngressHost ? "/products" : `http://${host}:30070`
  };
})();
