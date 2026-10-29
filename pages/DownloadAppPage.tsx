import React, { useState, useEffect } from 'react';
import { Download } from 'lucide-react';
import { resolveBrandLogo } from '../utils/brandLogo';

interface DownloadAppPageProps {
  companyLogo: string | null;
}

const DownloadAppPage: React.FC<DownloadAppPageProps> = ({ companyLogo }) => {
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);
  const [isInstalled, setIsInstalled] = useState(false);

  useEffect(() => {
    if (window.matchMedia('(display-mode: standalone)').matches) {
      setIsInstalled(true);
    }

    const handler = (e: any) => {
      e.preventDefault();
      setDeferredPrompt(e);
    };

    window.addEventListener('beforeinstallprompt', handler);

    window.addEventListener('appinstalled', () => {
      setIsInstalled(true);
      setDeferredPrompt(null);
    });

    return () => {
      window.removeEventListener('beforeinstallprompt', handler);
    };
  }, []);

  const handleInstallClick = async () => {
    if (!deferredPrompt) {
      alert("Para instalar neste dispositivo, use a opção 'Adicionar à Tela Inicial' no menu do seu navegador (geralmente ícone de compartilhamento no Safari ou três pontos no Chrome).");
      return;
    }
    
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    
    if (outcome === 'accepted') {
      setDeferredPrompt(null);
    }
  };

  const logoSrc = resolveBrandLogo(companyLogo, 'light');

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50 px-4 py-12">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl border border-slate-200/80 overflow-hidden text-center p-8">
        <img src={logoSrc} alt="Logo Tríade" className="h-24 mx-auto mb-6 object-contain" />
        
        <h1 className="text-2xl font-black text-[#011B35] mb-2">
          Aplicativo TRÍADE
        </h1>
        
        <p className="text-slate-600 mb-8">
          Instale nosso aplicativo para ter acesso rápido às suas cargas, histórico e muito mais, diretamente da tela inicial do seu celular.
        </p>
        
        {isInstalled ? (
          <div className="bg-emerald-50 text-emerald-700 p-4 rounded-xl font-medium border border-emerald-200">
            ✅ O aplicativo já está instalado neste dispositivo!
          </div>
        ) : (
          <div className="space-y-6">
            <button
              onClick={handleInstallClick}
              className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-[#EC2907] to-[#FF4D00] hover:from-[#C41C00] hover:to-[#EC2907] text-white text-lg font-bold py-4 px-8 rounded-xl shadow-lg shadow-orange-600/25 transition-transform transform hover:scale-[1.02]"
            >
              <Download className="w-6 h-6" />
              Instalar Aplicativo
            </button>
            
            <div className="text-sm text-slate-500 bg-slate-50 p-4 rounded-lg border border-slate-200">
              <p className="font-semibold mb-2 text-[#011B35]">Não conseguiu instalar?</p>
              <ul className="text-left list-disc list-inside space-y-1">
                <li><strong>No Android (Chrome):</strong> Toque nos três pontos (⋮) e escolha "Adicionar à tela inicial".</li>
                <li><strong>No iPhone (Safari):</strong> Toque no ícone de compartilhar (quadrado com seta para cima) e depois em "Adicionar à Tela de Início".</li>
              </ul>
            </div>
          </div>
        )}
      </div>
      
      <div className="mt-8 text-center">
        <a href="/" className="text-primary hover:underline font-semibold">
          Voltar para a tela inicial
        </a>
      </div>
    </div>
  );
};

export default DownloadAppPage;
