# Build context is the repo root (see docker-compose.yml) since this is a multi-project solution.
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY MyDent.Common.Services/MyDent.Common.Services.csproj MyDent.Common.Services/
COPY MyDent.Model/MyDent.Model.csproj MyDent.Model/
COPY MyDent.Services/MyDent.Services.csproj MyDent.Services/
COPY MyDent.WebAPI/MyDent.WebAPI.csproj MyDent.WebAPI/
RUN dotnet restore MyDent.WebAPI/MyDent.WebAPI.csproj

COPY MyDent.Common.Services/ MyDent.Common.Services/
COPY MyDent.Model/ MyDent.Model/
COPY MyDent.Services/ MyDent.Services/
COPY MyDent.WebAPI/ MyDent.WebAPI/
RUN dotnet publish MyDent.WebAPI/MyDent.WebAPI.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "MyDent.WebAPI.dll"]
