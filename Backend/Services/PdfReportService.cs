using FinanceHackathonAPI.DTOs;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace FinanceHackathonAPI.Services
{
    public interface IPdfReportService
    {
        byte[] GenerateMonthlyReport(ReportRequestDto data);
    }

    public class PdfReportService : IPdfReportService
    {
        // ── Renk sabitleri (QuestPDF Color struct) ────────────────────────────────
        private static readonly Color PrimaryBlue   = Color.FromHex("#1A3C5E");
        private static readonly Color AccentOrange  = Color.FromHex("#F4A425");
        private static readonly Color LightGray     = Color.FromHex("#F5F7FA");
        private static readonly Color TableStripe   = Color.FromHex("#EEF2F7");
        private static readonly Color SuccessGreen  = Color.FromHex("#2ECC71");
        private static readonly Color DangerRed     = Color.FromHex("#E74C3C");
        private static readonly Color WarningOrange = Color.FromHex("#E67E22");
        private static readonly Color PurpleColor   = Color.FromHex("#8E44AD");
        private static readonly Color DarkForest    = Color.FromHex("#1A6B3C");
        private static readonly Color FooterText    = Color.FromHex("#7A9BBD");
        private static readonly Color SubText       = Color.FromHex("#AABBCC");
        private static readonly Color BorderBlue    = Color.FromHex("#D0DCE8");
        private static readonly Color LegalYellow   = Color.FromHex("#FFF9EC");
        private static readonly Color LegalBorder   = Color.FromHex("#F0D58C");
        private static readonly Color LegalText     = Color.FromHex("#7D6608");
        private static readonly Color LightGreen    = Color.FromHex("#EAF7EF");
        private static readonly Color LightPurple   = Color.FromHex("#F5EEF8");
        private static readonly Color GrayText      = Color.FromHex("#555555");

        public PdfReportService()
        {
            // QuestPDF Community lisansı — ücretsiz, açık kaynak projelerde geçerli
            QuestPDF.Settings.License = LicenseType.Community;
        }

        public byte[] GenerateMonthlyReport(ReportRequestDto data)
        {
            decimal netBalance  = data.TotalIncome - data.TotalExpense;
            bool    isProfit    = netBalance >= 0;
            string  balanceLabel = isProfit ? "NET KÂR" : "NET ZARAR";
            Color   balanceColor = isProfit ? SuccessGreen : DangerRed;

            string reportTitle = data.AccountType.StartsWith("KOBI", StringComparison.OrdinalIgnoreCase)
                ? "KOBİ Aylık Finansal Röntgen Raporu"
                : "Bireysel Aylık Finansal Röntgen Raporu";

            var pdfBytes = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(0);
                    page.DefaultTextStyle(ts => ts.FontFamily("Arial").FontSize(10).FontColor(Colors.Grey.Darken4));

                    // ── HEADER ──────────────────────────────────────────────────────
                    page.Header().Height(110).Background(PrimaryBlue).Row(row =>
                    {
                        row.RelativeItem(3).Padding(24).Column(col =>
                        {
                            col.Item().Text("FinansAI").Bold().FontSize(22).FontColor(AccentOrange);
                            col.Item().Text(reportTitle).FontSize(12).FontColor(Colors.White).Bold();
                            col.Item().PaddingTop(6)
                               .Text($"Dönem: {data.ReportPeriod}  |  Hesap: {data.OwnerName}")
                               .FontSize(9).FontColor(SubText);
                        });
                        row.RelativeItem(1).AlignRight().AlignBottom().Padding(20)
                           .Text($"Oluşturuldu: {DateTime.Now:dd.MM.yyyy HH:mm}")
                           .FontSize(8).FontColor(SubText);
                    });

                    // ── BODY ────────────────────────────────────────────────────────
                    page.Content().Padding(28).Column(col =>
                    {
                        // 1. ÖZET KUTULAR
                        col.Item().PaddingBottom(18).Row(row =>
                        {
                            SummaryBox(row, "💰 Toplam Gelir",    data.TotalIncome,      SuccessGreen, LightGray);
                            row.ConstantItem(12);
                            SummaryBox(row, "💸 Toplam Gider",   data.TotalExpense,     DangerRed,    LightGray);
                            row.ConstantItem(12);
                            SummaryBox(row, $"📊 {balanceLabel}", Math.Abs(netBalance),  balanceColor, PrimaryBlue, invertText: true);
                        });

                        // 2. ALACAK / ÖDEME
                        if (data.PendingReceivables > 0 || data.UpcomingPayments > 0)
                        {
                            col.Item().PaddingBottom(18).Row(row =>
                            {
                                if (data.PendingReceivables > 0)
                                    SummaryBox(row, "⏳ Bekleyen Alacaklar", data.PendingReceivables, WarningOrange, LightGray);
                                if (data.PendingReceivables > 0 && data.UpcomingPayments > 0)
                                    row.ConstantItem(12);
                                if (data.UpcomingPayments > 0)
                                    SummaryBox(row, "📅 Yaklaşan Ödemeler", data.UpcomingPayments, PurpleColor, LightGray);
                                row.RelativeItem();
                            });
                        }

                        // 3. İŞLEM DETAYLARI
                        if (data.Transactions.Any())
                        {
                            col.Item().PaddingBottom(6)
                               .Text("📋 İşlem Detayları").Bold().FontSize(12).FontColor(PrimaryBlue);
                            col.Item().PaddingBottom(16).Table(table =>
                            {
                                table.ColumnsDefinition(cols =>
                                {
                                    cols.RelativeColumn(3);
                                    cols.RelativeColumn(2);
                                    cols.RelativeColumn(2);
                                    cols.RelativeColumn(2);
                                });
                                table.Header(h =>
                                {
                                    h.Cell().Background(PrimaryBlue).Padding(6).Text("Açıklama").Bold().FontColor(Colors.White);
                                    h.Cell().Background(PrimaryBlue).Padding(6).AlignRight().Text("Tutar (TL)").Bold().FontColor(Colors.White);
                                    h.Cell().Background(PrimaryBlue).Padding(6).AlignCenter().Text("Kategori").Bold().FontColor(Colors.White);
                                    h.Cell().Background(PrimaryBlue).Padding(6).AlignCenter().Text("Tarih").Bold().FontColor(Colors.White);
                                });

                                bool zebra = false;
                                foreach (var tx in data.Transactions)
                                {
                                    var bg = zebra ? TableStripe : Colors.White;
                                    var amtColor = tx.Amount >= 0 ? SuccessGreen : DangerRed;
                                    table.Cell().Background(bg).Padding(5).Text(tx.Description);
                                    table.Cell().Background(bg).Padding(5).AlignRight()
                                         .Text($"{tx.Amount:N2} ₺").Bold().FontColor(amtColor);
                                    table.Cell().Background(bg).Padding(5).AlignCenter().Text(tx.Category);
                                    table.Cell().Background(bg).Padding(5).AlignCenter().Text(tx.Date.ToString("dd.MM.yyyy"));
                                    zebra = !zebra;
                                }
                            });
                        }

                        // 4. SABİT GİDERLER  (FixedExpense: Description, Amount, DueDate)
                        if (data.FixedExpenses.Any())
                        {
                            col.Item().PaddingBottom(6)
                               .Text("🏦 Sabit Giderler").Bold().FontSize(12).FontColor(PrimaryBlue);
                            col.Item().PaddingBottom(16).Table(table =>
                            {
                                table.ColumnsDefinition(cols =>
                                {
                                    cols.RelativeColumn(5);
                                    cols.RelativeColumn(2);
                                    cols.RelativeColumn(2);
                                });
                                table.Header(h =>
                                {
                                    h.Cell().Background(PrimaryBlue).Padding(6).Text("Gider Açıklaması").Bold().FontColor(Colors.White);
                                    h.Cell().Background(PrimaryBlue).Padding(6).AlignRight().Text("Tutar (TL)").Bold().FontColor(Colors.White);
                                    h.Cell().Background(PrimaryBlue).Padding(6).AlignCenter().Text("Vade Tarihi").Bold().FontColor(Colors.White);
                                });

                                bool zebra = false;
                                foreach (var fe in data.FixedExpenses)
                                {
                                    var bg = zebra ? TableStripe : Colors.White;
                                    table.Cell().Background(bg).Padding(5).Text(fe.Description);
                                    table.Cell().Background(bg).Padding(5).AlignRight()
                                         .Text($"{fe.Amount:N2} ₺").Bold().FontColor(DangerRed);
                                    table.Cell().Background(bg).Padding(5).AlignCenter()
                                         .Text(fe.DueDate.ToString("dd.MM.yyyy"));
                                    zebra = !zebra;
                                }
                            });
                        }

                        // 5. FATURALAR  (Invoice: Description, Amount, DueDate, IsPaid)
                        if (data.Invoices.Any())
                        {
                            col.Item().PaddingBottom(6)
                               .Text("🧾 Faturalar / Ödenecekler").Bold().FontSize(12).FontColor(PrimaryBlue);
                            col.Item().PaddingBottom(16).Table(table =>
                            {
                                table.ColumnsDefinition(cols =>
                                {
                                    cols.RelativeColumn(3);
                                    cols.RelativeColumn(2);
                                    cols.RelativeColumn(2);
                                    cols.RelativeColumn(2);
                                });
                                table.Header(h =>
                                {
                                    h.Cell().Background(PurpleColor).Padding(6).Text("Fatura").Bold().FontColor(Colors.White);
                                    h.Cell().Background(PurpleColor).Padding(6).AlignRight().Text("Tutar").Bold().FontColor(Colors.White);
                                    h.Cell().Background(PurpleColor).Padding(6).AlignCenter().Text("Vade").Bold().FontColor(Colors.White);
                                    h.Cell().Background(PurpleColor).Padding(6).AlignCenter().Text("Durum").Bold().FontColor(Colors.White);
                                });

                                bool zebra = false;
                                foreach (var inv in data.Invoices)
                                {
                                    var bg         = zebra ? LightPurple : Colors.White;
                                    var statusText = inv.IsPaid ? "✅ Ödendi" : "⚠️ Bekliyor";
                                    var statusClr  = inv.IsPaid ? SuccessGreen : WarningOrange;
                                    table.Cell().Background(bg).Padding(5).Text(inv.Description);
                                    table.Cell().Background(bg).Padding(5).AlignRight().Text($"{inv.Amount:N2} ₺").Bold();
                                    table.Cell().Background(bg).Padding(5).AlignCenter().Text(inv.DueDate.ToString("dd.MM.yyyy"));
                                    table.Cell().Background(bg).Padding(5).AlignCenter()
                                         .Text(statusText).FontColor(statusClr).Bold();
                                    zebra = !zebra;
                                }
                            });
                        }

                        // 6. TAHSİLATLAR  (Collection: Description, Amount, ExpectedDate, IsCollected)
                        if (data.Collections.Any())
                        {
                            col.Item().PaddingBottom(6)
                               .Text("💼 Alacaklar / Tahsilatlar").Bold().FontSize(12).FontColor(PrimaryBlue);
                            col.Item().PaddingBottom(16).Table(table =>
                            {
                                table.ColumnsDefinition(cols =>
                                {
                                    cols.RelativeColumn(3);
                                    cols.RelativeColumn(2);
                                    cols.RelativeColumn(2);
                                    cols.RelativeColumn(2);
                                });
                                table.Header(h =>
                                {
                                    h.Cell().Background(DarkForest).Padding(6).Text("Açıklama / Müşteri").Bold().FontColor(Colors.White);
                                    h.Cell().Background(DarkForest).Padding(6).AlignRight().Text("Tutar").Bold().FontColor(Colors.White);
                                    h.Cell().Background(DarkForest).Padding(6).AlignCenter().Text("Beklenen Tarih").Bold().FontColor(Colors.White);
                                    h.Cell().Background(DarkForest).Padding(6).AlignCenter().Text("Durum").Bold().FontColor(Colors.White);
                                });

                                bool zebra = false;
                                foreach (var c in data.Collections)
                                {
                                    var bg          = zebra ? LightGreen : Colors.White;
                                    bool isLate     = !c.IsCollected && c.ExpectedDate < DateTime.Now;
                                    var statusText  = c.IsCollected ? "✅ Tahsil Edildi" : (isLate ? "🔴 GECİKMİŞ" : "🟡 Bekliyor");
                                    var statusClr   = c.IsCollected ? SuccessGreen : (isLate ? DangerRed : WarningOrange);
                                    table.Cell().Background(bg).Padding(5).Text(c.Description);
                                    table.Cell().Background(bg).Padding(5).AlignRight().Text($"{c.Amount:N2} ₺").Bold();
                                    table.Cell().Background(bg).Padding(5).AlignCenter()
                                         .Text(c.ExpectedDate.ToString("dd.MM.yyyy"));
                                    table.Cell().Background(bg).Padding(5).AlignCenter()
                                         .Text(statusText).FontColor(statusClr).Bold();
                                    zebra = !zebra;
                                }
                            });
                        }

                        // 7. GEMİNİ AKSİYON PLANI
                        if (!string.IsNullOrWhiteSpace(data.AiActionPlan))
                        {
                            col.Item().PaddingBottom(6)
                               .Text("🤖 Gemini AI – Aksiyon Planı").Bold().FontSize(12).FontColor(PrimaryBlue);
                            col.Item().PaddingBottom(8)
                               .Background(LightGray).Border(1).BorderColor(BorderBlue)
                               .Padding(14).Column(aiCol =>
                               {
                                   foreach (var line in data.AiActionPlan.Split('\n'))
                                   {
                                       var trimmed = line.Trim();
                                       if (string.IsNullOrEmpty(trimmed)) { aiCol.Item().PaddingTop(4); continue; }
                                       aiCol.Item().Text(trimmed).FontSize(9.5f);
                                   }
                               });
                        }

                        // 8. YASAL UYARI
                        col.Item().PaddingTop(10)
                           .Background(LegalYellow).Border(1).BorderColor(LegalBorder)
                           .Padding(10)
                           .Text("⚠️  Bu rapor bilgilendirme amaçlıdır ve yasal finansal belge niteliği taşımaz. " +
                                 "Karar vermeden önce sertifikalı bir mali müşavire danışınız.")
                           .FontSize(8).FontColor(LegalText).Italic();
                    });

                    // ── FOOTER ──────────────────────────────────────────────────────
                    page.Footer().Height(36).Background(PrimaryBlue).Row(row =>
                    {
                        row.RelativeItem().AlignMiddle().Padding(12)
                           .Text("© 2026 FinansAI – Yapay Zeka Destekli Kişisel Finans Asistanı")
                           .FontSize(8).FontColor(FooterText);
                        row.ConstantItem(120).AlignMiddle().AlignRight().Padding(12)
                           .Text(x =>
                           {
                               x.Span("Sayfa ").FontColor(FooterText).FontSize(8);
                               x.CurrentPageNumber().Bold().FontColor(AccentOrange).FontSize(8);
                               x.Span(" / ").FontColor(FooterText).FontSize(8);
                               x.TotalPages().Bold().FontColor(AccentOrange).FontSize(8);
                           });
                    });
                });
            }).GeneratePdf();

            return pdfBytes;
        }

        // ── Yardımcı: Özet kutu ────────────────────────────────────────────────────
        private static void SummaryBox(RowDescriptor row, string title, decimal value,
                                       Color accentColor, Color bgColor, bool invertText = false)
        {
            var textColor  = invertText ? Colors.White : Colors.Grey.Darken3;
            var labelColor = invertText ? SubText : GrayText;

            row.RelativeItem()
               .Background(bgColor).Border(2).BorderColor(accentColor)
               .Padding(14).Column(col =>
               {
                   col.Item().Text(title).FontSize(9).FontColor(labelColor).Bold();
                   col.Item().PaddingTop(6).Text($"{value:N2} ₺")
                      .Bold().FontSize(18).FontColor(invertText ? Colors.White : accentColor);
               });
        }
    }
}
