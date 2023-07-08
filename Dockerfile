FROM dart:stable as build

LABEL org.opencontainers.image.source=https://github.com/enjin/platform-decoder
LABEL org.opencontainers.image.description="Enjin Platform - Decoder"
LABEL org.opencontainers.image.licenses=LGPL-3.0-only

# Resolve app dependencies.
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# Start server.
EXPOSE 8090
CMD ["/app/bin/server"]