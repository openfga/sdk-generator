FROM mono

RUN mozroots --import --sync
RUN nuget update -self

WORKDIR /data

ENTRYPOINT ["nuget"]
CMD ["help"]
