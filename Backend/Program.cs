using FinanceHackathonAPI.Services;
using Hangfire;
using Hangfire.MemoryStorage;
using Hangfire.Dashboard.BasicAuthorization;

var builder = WebApplication.CreateBuilder(args);

// Controller'ları servise ekle
builder.Services.AddControllers();

// Swagger (Dokümantasyon)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS Politikası: Frontend ekibinin her yerden istek atabilmesi için (Hackathon ortamı için serbest bırakıyoruz)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Dependency Injection (SOLID'in D'si) - HttpClient ile birlikte servisimizi kaydediyoruz
builder.Services.AddHttpClient<IGeminiService, GeminiService>();

// RAG (Retrieval-Augmented Generation) Servisini Singleton olarak ekleyelim (Uygulama açık kaldığı sürece veriler silinmesin)
builder.Services.AddSingleton<IRagService, RagService>();

// E-posta servisini kaydet
builder.Services.AddTransient<IEmailService, EmailService>();

// PDF Rapor servisini kaydet (Aylık Finansal Röntgen)
builder.Services.AddTransient<IPdfReportService, PdfReportService>();

// Hangfire Kurulumu (Arka plan işleri için, In-Memory olarak kuruluyor)
builder.Services.AddHangfire(config => config.UseMemoryStorage());
builder.Services.AddHangfireServer();

// Yaklaşan ödemeleri haber edecek olan basit servisi kapattık (Yerine Hangfire kullanıyoruz)
// builder.Services.AddHostedService<PaymentReminderService>();

// QuestPDF Lisansı (Ücretsiz Community mod)
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

var app = builder.Build();

// Swagger'ı her ortamda aktif et (Development + Production)
// Yayına alındıktan sonra da jüri ve takım /swagger üzerinden API'yi test edebilir
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "KOBİ Finans API v1");
    c.RoutePrefix = "swagger"; // /swagger adresinden erişilir
});

app.UseHttpsRedirection();

// Hangfire Dashboard — Şifre korumalı (appsettings.json'dan okunur)
// Kullanıcı adı: HangfireSettings:Username | Şifre: HangfireSettings:Password
// Hangfire Dashboard — Şifre korumalı (appsettings.json'dan okunur)
var hangfireUser = builder.Configuration["HangfireSettings:Username"] ?? "admin";
var hangfirePass = builder.Configuration["HangfireSettings:Password"] ?? "admin4273";

app.UseHangfireDashboard("/hangfire", new DashboardOptions
{
    Authorization = new[]
    {
        new BasicAuthAuthorizationFilter(
            new BasicAuthAuthorizationFilterOptions
            {
                RequireSsl = false,
                SslRedirect = false,
                LoginCaseSensitive = true,
                Users = new[]
                {
                    new BasicAuthAuthorizationUser
                    {
                        Login = hangfireUser,
                        PasswordClear = hangfirePass
                    }
                }
            }
        )
    }
});

// CORS'u middleware'e ekle (Authorization'dan önce olmalı!)
app.UseCors("AllowAll");

app.UseAuthorization();
app.MapControllers();

app.Run();