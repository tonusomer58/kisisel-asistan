using FinanceHackathonAPI.Services;

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

var app = builder.Build();

// Swagger'ı aktif et
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// CORS'u middleware'e ekle (Authorization'dan önce olmalı!)
app.UseCors("AllowAll");

app.UseAuthorization();
app.MapControllers();

app.Run();