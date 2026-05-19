# 1. Aşama: Build (Derleme)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Sadece csproj dosyasını kopyala ve paketleri indir (Önbellek optimizasyonu)
COPY ["FinanceHackathonAPI.csproj", "./"]
RUN dotnet restore "./FinanceHackathonAPI.csproj"

# Tüm kodları kopyala ve yayına hazır (Release) hale getir
COPY . .
RUN dotnet publish "FinanceHackathonAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

# 2. Aşama: Runtime (Çalıştırma)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "FinanceHackathonAPI.dll"]