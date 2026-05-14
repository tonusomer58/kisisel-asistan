import React, { useState } from 'react';
import { 
  Wallet, 
  MessageSquare, 
  TrendingDown, 
  BarChart3, 
  BellRing, 
  FastForward, 
  ShieldCheck, 
  ArrowRight,
  ChevronRight,
  Send
} from 'lucide-react';
import './index.css';

function App() {
  const [activeTab, setActiveTab] = useState('bireysel');

  return (
    <>
      {/* 1. Hero Bölümü */}
      <section className="hero">
        <div className="hero-bg-glow"></div>
        <div className="container">
          <h1>Finansal Geleceğinizi Yapay Zeka ile Yönetin: <br/><span className="text-gradient">İster Evde, İster Şirkette.</span></h1>
          <p>
            Kişisel bütçenizden KOBİ nakit akışınıza kadar tüm finansal süreçlerinizi analiz edin, geleceği tahmin edin ve yapay zeka asistanınızla sohbet ederek doğru kararlar alın.
          </p>
          <div className="hero-buttons">
            <button className="btn btn-primary" onClick={() => setActiveTab('bireysel')}>
              Bireysel İçin Başla
            </button>
            <button className="btn btn-secondary" onClick={() => setActiveTab('kobi')}>
              KOBİ'ler İçin Keşfet
            </button>
          </div>

          {/* Chat Mockup in Hero */}
          <div className="chat-mockup-wrapper">
            <div className="chat-header">
              <div className="chat-header-dot dot-red"></div>
              <div className="chat-header-dot dot-yellow"></div>
              <div className="chat-header-dot dot-green"></div>
              <div className="chat-header-title">FinAI Asistan</div>
            </div>
            <div className="chat-body">
              <div className="chat-message user">
                Bu ay neden daha fazla harcadım?
              </div>
              <div className="chat-message ai">
                Analizlerime göre, bu ay <strong>"Dışarıda Yemek"</strong> kategorisinde geçen aya kıyasla <strong>%40</strong> daha fazla harcama yaptınız. Ayrıca beklenmedik bir <strong>"Araç Bakımı"</strong> gideriniz oldu. Bu harcamaları dengelemek için önümüzdeki 2 hafta market alışverişlerinizi optimize edebiliriz.
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 2. Özellikler Bölümü */}
      <section className="features">
        <div className="container">
          <div className="section-header">
            <h2>Size Özel Finansal Zeka</h2>
            <p className="text-muted">İhtiyacınıza uygun çözümleri keşfedin.</p>
          </div>

          <div className="toggle-container">
            <div className="toggle-switch" data-active={activeTab}>
              <div className="toggle-indicator"></div>
              <button 
                className={`toggle-btn ${activeTab === 'bireysel' ? 'active' : ''}`}
                onClick={() => setActiveTab('bireysel')}
              >
                Bireysel
              </button>
              <button 
                className={`toggle-btn ${activeTab === 'kobi' ? 'active' : ''}`}
                onClick={() => setActiveTab('kobi')}
              >
                KOBİ
              </button>
            </div>
          </div>

          {activeTab === 'bireysel' ? (
            <div className="feature-grid">
              <div className="feature-card">
                <div className="feature-icon">
                  <Wallet size={24} />
                </div>
                <h3>Kişiselleştirilmiş Bütçe Planı</h3>
                <p>Gelir, gider, hedef ve alışkanlıklarınıza göre otomatik olarak adapte olan dinamik bütçe planları oluşturur.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">
                  <MessageSquare size={24} />
                </div>
                <h3>Akıllı Soru-Cevap</h3>
                <p>"3 ayda tatil için nasıl para biriktiririm?" gibi sorularınıza veriye dayalı, anlaşılır ve eyleme geçirilebilir yanıtlar verir.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">
                  <TrendingDown size={24} />
                </div>
                <h3>Kategori Bazlı Analiz ve Tasarruf</h3>
                <p>Harcamalarınızı milisaniyeler içinde analiz ederek kişiye özel, proaktif ve gerçekçi tasarruf önerileri sunar.</p>
              </div>
            </div>
          ) : (
            <div className="feature-grid">
              <div className="feature-card">
                <div className="feature-icon">
                  <BarChart3 size={24} />
                </div>
                <h3>Tam Kapsamlı Finansal Analiz</h3>
                <p>Küçük işletmelerin gelir-gider, nakit akışı, fatura ve tahsilat durumunu saniyeler içinde analiz eder.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">
                  <BellRing size={24} />
                </div>
                <h3>Risk ve Gecikme Bildirimleri</h3>
                <p>Yaklaşan ödemeleri, geciken alacakları ve olası nakit sıkışıklığı risklerini önceden özetler ve uyarır.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">
                  <FastForward size={24} />
                </div>
                <h3>Gelecek Simülasyonu</h3>
                <p>"Önümüzdeki ay maaşları ödeyebilir miyim?" sorusuna mevcut finansal veriler üzerinden simülasyonlarla net cevaplar verir.</p>
              </div>
            </div>
          )}
          
          {activeTab === 'kobi' && (
            <div className="chat-mockup-wrapper" style={{ marginTop: '3rem', marginInline: 'auto' }}>
              <div className="chat-header">
                <div className="chat-header-dot dot-red"></div>
                <div className="chat-header-dot dot-yellow"></div>
                <div className="chat-header-dot dot-green"></div>
                <div className="chat-header-title">FinAI Asistan (KOBİ)</div>
              </div>
              <div className="chat-body" style={{ padding: '1.5rem' }}>
                <div className="chat-message user">
                  Maaşları ve kira ödemelerini rahat karşılayabilir miyim?
                </div>
                <div className="chat-message ai">
                  Evet, bu ayki beklenen tahsilatlarla maaşları ve kirayı <strong>%100 güvence altına aldınız</strong>. Ayrıca, tedarikçi ödemelerinden sonra kasada <strong>₺45,000</strong> nakit fazlanız kalması öngörülüyor.
                </div>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* 3. Nasıl Çalışır? */}
      <section className="how-it-works">
        <div className="container">
          <div className="section-header">
            <h2>Nasıl Çalışır?</h2>
            <p className="text-muted">Üç basit adımda finansal kontrolü elinize alın.</p>
          </div>
          
          <div className="steps-container">
            <div className="step-item">
              <div className="step-number">1</div>
              <h3>Bağlayın</h3>
              <p>Banka hesaplarınızı veya muhasebe yazılımınızı saniyeler içinde güvenle entegre edin.</p>
            </div>
            <div className="step-item">
              <div className="step-number">2</div>
              <h3>Analiz Edin</h3>
              <p>Yapay zeka tüm verilerinizi otomatik olarak okusun, kategorize etsin ve anlamlandırsın.</p>
            </div>
            <div className="step-item">
              <div className="step-number">3</div>
              <h3>Sohbet Edin</h3>
              <p>Asistanınızla chat yapmaya başlayın, doğru kararlar alarak finansal sağlığınızı iyileştirin.</p>
            </div>
          </div>
        </div>
      </section>

      {/* 4. Güvenlik ve Gizlilik */}
      <section className="trust">
        <div className="container">
          <div className="trust-content">
            <ShieldCheck size={48} color="var(--accent-green)" />
            <div>
              <h3 style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>Banka Düzeyinde Güvenlik</h3>
              <p>
                256-bit uçtan uca şifreleme ile korunursunuz. <strong>Verileriniz sadece size aittir</strong> ve hiçbir şekilde yapay zeka modellerimizi genel olarak eğitmek için kullanılmaz.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 5. Footer & Son Çağrı */}
      <footer className="footer-cta">
        <div className="container">
          <h2>Finansal stresinizi yapay zekaya devredin.</h2>
          <p className="text-muted" style={{ marginBottom: '2.5rem', fontSize: '1.2rem' }}>
            Ücretsiz denemeye bugün başlayın, farkı kendi verilerinizle görün.
          </p>
          
          <form className="signup-form" onSubmit={(e) => e.preventDefault()}>
            <input type="email" placeholder="E-posta adresinizi girin..." required />
            <button type="submit">Hemen Başla</button>
          </form>
        </div>
        
        <div className="footer-bottom" style={{ marginTop: '4rem' }}>
          <div className="container">
            <p>&copy; {new Date().getFullYear()} FinAI Asistan. Tüm hakları saklıdır.</p>
          </div>
        </div>
      </footer>
    </>
  );
}

export default App;
