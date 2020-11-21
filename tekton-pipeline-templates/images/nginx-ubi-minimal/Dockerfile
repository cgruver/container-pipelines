FROM registry.access.redhat.com/ubi8/ubi-minimal:8.1
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en'
RUN microdnf install nginx \
    && microdnf update \
    && microdnf clean all \
    && mkdir /var/cache/nginx \
    && chown -R nginx:0 /var/log/nginx/ /var/cache/nginx /usr/share/nginx \
    && chmod -R "g+rwX" /var/log/nginx/ /var/cache/nginx /usr/share/nginx

COPY html-content-dir /usr/share/nginx/html/

EXPOSE 80
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
