FROM microsoft/dotnet:2.1-sdk-alpine AS build-env

WORKDIR /app

COPY *.csproj ./
RUN dotnet restore

COPY . ./
RUN dotnet publish -c Release -o out

# build
FROM microsoft/dotnet:2.1-aspnetcore-runtime-alpine
RUN adduser -D myuser
USER myuser
WORKDIR /app
COPY --from=build-env /app/out .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
CMD ["dotnet", "TodoApi.dll"]
