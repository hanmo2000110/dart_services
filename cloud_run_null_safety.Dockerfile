FROM dart:2.13.1-sdk

# We install unzip and remove the apt-index again to keep the
# docker image diff small.
RUN apt-get update && \
  apt-get install -y git unzip && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN groupadd --system dart && \
  useradd --no-log-init --system --home /home/dart --create-home -g dart dart
RUN usermod -a -G dart root
RUN chown dart:dart /app
RUN chown -R dart:dart /usr/lib/dart

# Switch to a new, non-root user to use the flutter tool.
# The Flutter tool won't perform its actions when run as root.
USER dart

COPY --chown=dart:dart tool/dart_cloud_run.sh /dart_runtime/
RUN chmod a+x /dart_runtime/dart_cloud_run.sh
COPY --chown=dart:dart pubspec.* /app/
RUN pub get
COPY --chown=dart:dart . /app
RUN pub get --offline

ENV PATH="/home/dart/.pub-cache/bin:${PATH}"

# Set the Flutter SDK up for web compilation.
RUN dart pub run grinder setup-flutter-sdk

# Build the dill file
RUN dart pub run grinder build-storage-artifacts validate-storage-artifacts

# Clear out any arguments the base images might have set and ensure we start
# the Dart app using custom script enabling debug modes.
CMD []

ENTRYPOINT ["/dart_runtime/dart_cloud_run.sh", "--port", "${PORT}", \
  "--redis-url", "redis://10.0.0.4:6379", "--null-safety"]