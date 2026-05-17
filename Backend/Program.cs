using FinanceHackathonAPI.Services;
using Hangfire;
using Hangfire.MemoryStorage;

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

// Hangfire Kurulumu (Arka plan işleri için, In-Memory olarak kuruluyor)
builder.Services.AddHangfire(config => config.UseMemoryStorage());
builder.Services.AddHangfireServer();

// Yaklaşan ödemeleri haber edecek olan basit servisi kapattık (Yerine Hangfire kullanıyoruz)
// builder.Services.AddHostedService<PaymentReminderService>();

var app = builder.Build();

// Swagger'ı aktif et
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Hangfire Dashboard (http://localhost:port/hangfire adresinden zamanlanmış görevleri canlı izleyebilirsin)
app.UseHangfireDashboard();

// CORS'u middleware'e ekle (Authorization'dan önce olmalı!)
app.UseCors("AllowAll");

app.UseAuthorization();
app.MapControllers();

app.Run();