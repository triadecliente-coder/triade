import React from 'react';
import Header from '../components/Header';
import ImageUploader from '../components/ImageUploader';
import { Moon, Sun, CheckCircle2, Sparkles } from 'lucide-react';
import { resolveBrandLogo } from '../utils/brandLogo';

interface AppearancePageProps {
  currentLogo: string | null;
  onSaveLogo: (logoBase64: string) => void;
  currentTheme: string | null;
  onSaveTheme: (themeBase64: string) => void;
  themeMode?: 'dark' | 'light';
  onThemeModeChange?: (mode: 'dark' | 'light') => void;
}

const AppearancePage: React.FC<AppearancePageProps> = ({ 
  currentLogo, 
  onSaveLogo, 
  currentTheme, 
  onSaveTheme,
  themeMode = 'dark',
  onThemeModeChange
}) => {
  const effectivePreviewLogo = resolveBrandLogo(currentLogo, themeMode === 'dark' ? 'dark' : 'light');

  return (
    <>
      <Header title="Gestão de Aparência" />
      <div className="space-y-8">
        {/* Escolha do Fundo: Escuro ou Claro */}
        <div className="p-6 rounded-2xl bg-white dark:bg-[#0A1C34]/90 border border-slate-200 dark:border-slate-700/60 shadow-xl backdrop-blur-xl transition-all">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary dark:text-accent">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-800 dark:text-white">Estilo Visual e Fundo do Sistema</h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Selecione o esquema de cores Tríade para o painel operacional e navegação interna.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-6">
            {/* Opção Fundo Escuro */}
            <button
              type="button"
              onClick={() => onThemeModeChange && onThemeModeChange('dark')}
              className={`relative p-5 rounded-2xl text-left border-2 transition-all flex flex-col justify-between overflow-hidden group ${
                themeMode === 'dark'
                  ? 'border-accent bg-[#041020] text-white shadow-xl shadow-orange-950/40 ring-2 ring-accent/25'
                  : 'border-slate-200 dark:border-slate-800 bg-[#041020]/95 text-slate-300 hover:border-slate-400'
              }`}
            >
              <div 
                className="absolute inset-0 pointer-events-none opacity-30"
                style={{
                  backgroundImage: `
                    linear-gradient(to right, rgba(236, 41, 7, 0.12) 1px, transparent 1px),
                    linear-gradient(to bottom, rgba(236, 41, 7, 0.12) 1px, transparent 1px)
                  `,
                  backgroundSize: '24px 24px'
                }}
              />
              <div className="relative z-10 flex items-center justify-between mb-4">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-xl bg-primary/20 border border-accent/40 flex items-center justify-center text-accent">
                    <Moon className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="font-extrabold text-sm text-white flex items-center gap-1.5">
                      Fundo Escuro Navy Tríade
                      <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-primary/20 border border-accent/50 text-orange-300">
                        Padrão Login
                      </span>
                    </h3>
                    <p className="text-xs text-slate-400">Azul Marinho Meia-Noite (#011B35) com destaques Vermelho-Laranja Tríade</p>
                  </div>
                </div>
                {themeMode === 'dark' && (
                  <CheckCircle2 className="w-6 h-6 text-accent shrink-0" />
                )}
              </div>

              {/* Preview UI Bar */}
              <div className="relative z-10 w-full p-2.5 rounded-lg bg-[#0A1C34] border border-slate-700/80 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-primary" />
                  <div className="h-2 w-16 bg-slate-700 rounded-full" />
                </div>
                <div className="h-2 w-8 bg-accent rounded-full" />
              </div>
            </button>

            {/* Opção Fundo Claro */}
            <button
              type="button"
              onClick={() => onThemeModeChange && onThemeModeChange('light')}
              className={`relative p-5 rounded-2xl text-left border-2 transition-all flex flex-col justify-between overflow-hidden group ${
                themeMode === 'light'
                  ? 'border-primary bg-slate-50 text-slate-900 shadow-xl shadow-orange-500/10 ring-2 ring-primary/20'
                  : 'border-slate-200 dark:border-slate-800 bg-slate-100 text-slate-700 hover:border-slate-400'
              }`}
            >
              <div className="relative z-10 flex items-center justify-between mb-4">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-xl bg-amber-500/20 border border-amber-500/40 flex items-center justify-center text-amber-500">
                    <Sun className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="font-extrabold text-sm text-slate-900 flex items-center gap-1.5">
                      Fundo Claro
                      <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-slate-200 border border-slate-300 text-slate-700">
                        Clássico
                      </span>
                    </h3>
                    <p className="text-xs text-slate-500">Interface clara com tipografia Navy Tríade e ações em Vermelho-Laranja</p>
                  </div>
                </div>
                {themeMode === 'light' && (
                  <CheckCircle2 className="w-6 h-6 text-primary shrink-0" />
                )}
              </div>

              {/* Preview UI Bar */}
              <div className="relative z-10 w-full p-2.5 rounded-lg bg-white border border-slate-300 flex items-center justify-between shadow-sm">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-primary" />
                  <div className="h-2 w-16 bg-slate-200 rounded-full" />
                </div>
                <div className="h-2 w-8 bg-brand-navy rounded-full" />
              </div>
            </button>
          </div>
        </div>

        {/* Uploads de Imagens */}
        <ImageUploader
          title="Logo da Empresa"
          description="Faça o upload do logo que será exibido na barra superior e na tela de login (limite de 2MB). Remover restaura a logo oficial da Tríade."
          currentImage={effectivePreviewLogo}
          onSave={onSaveLogo}
          onRemove={() => onSaveLogo('')}
        />
        <ImageUploader
          title="Tema de Fundo Personalizado"
          description="Imagem de fundo opcional para o sistema. Se configurada, será aplicada sobre o fundo base (limite de 5MB)."
          currentImage={currentTheme}
          onSave={onSaveTheme}
          onRemove={() => onSaveTheme('')}
          maxSizeMB={5}
        />
      </div>
    </>
  );
};

export default AppearancePage;
