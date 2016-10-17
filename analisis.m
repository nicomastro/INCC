format long g;

%% Leer CSV a variables aux
i = 0;
sujeto = [];
tiempo = [];
practica = [];
delay = [];
img = [];
snd = [];
target = [];
total_trials = [];
target_time = cell(1,1);
time_firstPress = cell(1,1);
time_lastPress = cell(1,1);
f = fopen('data/bloques.csv');

while 1    
    suj = fscanf(f, '%i,', [1 1]);
    if isempty(suj)
       break 
    end
    i = i + 1;
    
    sujeto(i) = suj;
    tiempo(i) = fscanf(f, '%f,', [1 1]);
    practica(i) = fscanf(f, '%i,', [1 1]);
    delay(i) = fscanf(f, '%f,', [1 1]);
    img(i) = fscanf(f, '%i,', [1 1]);
    snd(i) = fscanf(f, '%i,', [1 1]);
    target(i) = fscanf(f, '%i,', [1 1]);
    total_trials(i) = fscanf(f, '%i,', [1 1]);
    target_time{i} = fscanf(f, '%f:', [1 total_trials(i)]);
    fscanf(f, ',');
    time_firstPress{i} = fscanf(f, '%f:', [1 total_trials(i)]);
    fscanf(f, ',');
    time_lastPress{i} = fscanf(f, '%f:', [1 total_trials(i)]);
    fscanf(f, ',');
    fscanf(f, '\n');
end
fclose(f);


%% Meter cada trial en el struct Trials sin procesarlos
num_bloques = i;
j = 1;
s = 0;
Trials = [];
for b = 1 : num_bloques
   if s ~= sujeto(b)
       bloque_del_sujeto = 1;
       s = sujeto(b);
   else
       bloque_del_sujeto = bloque_del_sujeto + 1;
   end
   
   for k = 1 : total_trials(b)
       Trials(j).Sujeto = sujeto(b);
       Trials(j).Tiempo = tiempo(b);
       Trials(j).EsDePractica = practica(b);
       Trials(j).Delay = delay(b);
       Trials(j).HayImagen = img(b);
       Trials(j).HaySonido = snd(b);
       Trials(j).SeguirImagen = target(b);
       Trials(j).NumBloque = bloque_del_sujeto;
       Trials(j).NumBloqueOriginal = b;
       Trials(j).NumTrial = k;       
       Trials(j).TiempoObjetivo = target_time{b}(k);
       Trials(j).PrimerTap = time_firstPress{b}(k);
       Trials(j).Asincronia = Trials(j).PrimerTap - Trials(j).TiempoObjetivo;
       Trials(j).UltimoTap = time_lastPress{b}(k);
        
       j = j + 1;    
   end
end

num_trials = j-1;



clear sujeto tiempo practica delay img snd target bloque_del_sujeto total_trials target_time time_firstPress time_lastPress f b i j k s num_bloques suj

%% calcular muestras (promedio de cada bloque)
Muestras = [];
t = 1;
m = 1;
k = 0;
asinc = 0;
unbo = Trials(1).NumBloqueOriginal;
while t <= (num_trials + 1)

    if t == (num_trials + 1) || unbo ~= Trials(t).NumBloqueOriginal

        if k ~=0 
            
            Muestras(m).AsinMedia = asinc / k;
            Muestras(m).Sujeto = Trials(t-1).Sujeto;
            Muestras(m).EsDePractica = Trials(t-1).EsDePractica;
            Muestras(m).Delay = Trials(t-1).Delay;
            Muestras(m).HayImagen = Trials(t-1).HayImagen;
            Muestras(m).HaySonido = Trials(t-1).HaySonido;
            Muestras(m).SeguirImagen = Trials(t-1).SeguirImagen;
            Muestras(m).Accuracy = 1 - (ignorados/(k+ignorados));

            
            Muestras(m).Tiempo = Trials(t-1).Tiempo;
            Muestras(m).TiempoObjetivo = Trials(t-1).TiempoObjetivo;
            Muestras(m).NumBloqueOriginal = Trials(t-1).NumBloqueOriginal;
            m = m + 1;
        end
        
        k = 0;
        asinc = 0;
        if (t == (num_trials + 1))
        	break
        end
    end
    
    ignorados = 0;
    % ignorar cuando no apreto nada
    if Trials(t).PrimerTap == -1
        ignorados = ignorados + 1;
    end
    
    % ignorar casos donde pega la vuelta (igual estan re afuera de la ventana)
    if Trials(t).Asincronia < -0.5
        ignorados = ignorados + 1;
    end
    
    
    if ignorados == 0
        asinc = asinc + Trials(t).Asincronia;
        k = k + 1;
    end
        
    unbo = Trials(t).NumBloqueOriginal;
    t = t + 1;
end

%% RECONSTRUYENDO LOS SIGNOS DEL DELAY

ds = [0.1, 0.3, 0.4];

corte = [];
es_negativo = [];
es_positivo = [];
es_practica = [];

for segu = 1:2
    for iid = 1:3
        eee = [Muestras( ...
                [Muestras.EsDePractica] == 0 & ...
                [Muestras.Delay] == ds(iid) & ...
                [Muestras.SeguirImagen] == (segu-1) & ...
                [Muestras.HayImagen] == 1 & ...
                [Muestras.HaySonido] == 1)];
            
        jose = [];
        for e = 1: numel(eee)
            jose(e) = [0.5 - (eee(e).Tiempo - eee(e).TiempoObjetivo)];
        end

        m = mean(jose);
        d = ds(iid);
        s = (segu-1);
        %disp([m, d, s]);
        corte(iid, segu) = m;
        
        for i = 1:numel(Muestras)
            es_practica(Muestras(i).NumBloqueOriginal) = Muestras(i).EsDePractica;
            
            if Muestras(i).Delay == ds(iid) && Muestras(i).SeguirImagen == (segu-1)
                delay_es_negativo = ( ...
                    (Muestras(i).EsDePractica == 0) & ...
                    (Muestras(i).Delay == ds(iid)) & ...
                    (Muestras(i).SeguirImagen == (segu-1)) & ...
                    (Muestras(i).HayImagen == 1) & ...
                    (Muestras(i).HaySonido == 1) & ...
                    ((0.5 - (Muestras(i).Tiempo - Muestras(i).TiempoObjetivo) > corte(iid, segu)) ~= Muestras(i).SeguirImagen) ...
                );

                delay_es_positivo = ( ...
                    (Muestras(i).EsDePractica == 0) & ...
                    (Muestras(i).Delay == ds(iid)) & ...
                    (Muestras(i).SeguirImagen == (segu-1)) & ...
                    (Muestras(i).HayImagen == 1) & ...
                    (Muestras(i).HaySonido == 1) & ...
                    ((0.5 - (Muestras(i).Tiempo - Muestras(i).TiempoObjetivo) > corte(iid, segu)) == Muestras(i).SeguirImagen) ...
                );

                es_negativo(Muestras(i).NumBloqueOriginal) = delay_es_negativo;
                es_positivo(Muestras(i).NumBloqueOriginal) = delay_es_positivo;
            end
        end
    end
end


% arreglar
for i = 1:numel(Muestras)
    b = Muestras(i).NumBloqueOriginal;
    
    if es_negativo(b)
        Muestras(i).Delay = -1 * Muestras(i).Delay;
    end
end



%% cuentitas cuentitas
mi=1;
ms=1;
mc0=1;
mc1=1;
mc2=1;
mc3=1;
mc4=1;
mc5=1;
mc6=1;
deltas = cell(1,1);
deltas_img = [];
deltas_snd = [];
deltas_combinados_0 = [];
m_accuracy = cell(1,1);


sujs = unique([Muestras.Sujeto]);
for s = 1:numel(sujs)
    suj = sujs(s);
    
   
    %bloques de sonido y su accuracy
    delta_snd = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 0 & ...
        [Muestras.HaySonido] == 1 ...
    ).AsinMedia];
    

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 0 & ...
        [Muestras.HaySonido] == 1 ...
    ).Accuracy];
    
    if numel(delta_snd) > 0
        deltas{1}(ms) = delta_snd(1);
        m_accuracy{1}(ms) = accuracy;
        ms = ms + 1;
    end
    
    %bloques de imagen y su accuracy
    delta_img = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 0 ...
    ).Accuracy];


    if numel(delta_img) > 0
        deltas{2}(mi) = delta_img(1);
        m_accuracy{2}(mi) = accuracy;
        mi = mi + 1;
    end
    
    %bloques combinados +0 y su accuracy
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{3}(mc0) = delta_c0(1);
        m_accuracy{3}(mc0) = accuracy(1);
        mc0 = mc0 + 1;
    end
    
     %bloques combinados +0.1 y su accuracy(seguir Imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.1 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.1 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{4}(mc1) = delta_c0(1);
        m_accuracy{4}(mc1) = accuracy(1);
        mc1 = mc1 + 1;
    end
    
     %bloques combinados +0.3 y su accuracy(seguir imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.3 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.3 & ... 
        [Muestras.SeguirImagen] == 1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{5}(mc2) = delta_c0(1);
        m_accuracy{5}(mc2) = accuracy(1);
        mc2 = mc2 + 1;
    end
    
     %bloques combinados +0.4 y su accuracy(seguir imagen)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.4 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.4 & ...
        [Muestras.SeguirImagen] == 1 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{6}(mc3) = delta_c0(1);
        m_accuracy{6}(mc3) = accuracy(1);
        mc3 = mc3 + 1;
    end
    
    
     %bloques combinados +0.4 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.4 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.4 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{7}(mc4) = delta_c0(1);
        m_accuracy{7}(mc4) = accuracy(1);
        mc4 = mc4 + 1;
    end
    
    
    
     %bloques combinados +0.3 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.3 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.3 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{8}(mc5) = delta_c0(1);
        m_accuracy{8}(mc5) = accuracy(1);
        mc5 = mc5 + 1;
    end
    
    
    
     %bloques combinados +0.1 y su accuracy(seguir sonido)
     delta_c0 = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.1 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).AsinMedia];

    accuracy = [Muestras( ...
        [Muestras.Sujeto] == suj & ...
        [Muestras.EsDePractica] == 0 & ...
        [Muestras.HayImagen] == 1 & ...
        [Muestras.HaySonido] == 1 & ...
        [Muestras.Delay] == 0.1 & ...
        [Muestras.SeguirImagen] == 0 ...
    ).Accuracy];


    if numel(delta_c0) > 0
        deltas{9}(mc6) = delta_c0(1);
        m_accuracy{9}(mc6) = accuracy(1);
        mc6 = mc6 + 1;
    end
    
    
%     CAMBIAR INDICES!    
%     %bloques combinados -0.4 y su accuracy
%      delta_c0 = [Muestras( ...
%         [Muestras.Sujeto] == suj & ...
%         [Muestras.EsDePractica] == 0 & ...
%         [Muestras.HayImagen] == 1 & ...
%         [Muestras.HaySonido] == 1 & ...
%         [Muestras.Delay] == -0.4 ...
%     ).AsinMedia];
% 
%     accuracy = [Muestras( ...
%         [Muestras.Sujeto] == suj & ...
%         [Muestras.EsDePractica] == 0 & ...
%         [Muestras.HayImagen] == 1 & ...
%         [Muestras.HaySonido] == 1 & ...
%         [Muestras.Delay] == -0.4 ...
%     ).Accuracy];
% 
% 
%     if numel(delta_c0) > 0
%         disp('hola0')
%         deltas{7}(mc4) = delta_c0(1);
%         m_accuracy{7}(mc4) = accuracy(1);
%         mc4 = mc4 + 1;
%     end
%     
%     %bloques combinados -0.3 y su accuracy
%      delta_c0 = [Muestras( ...
%         [Muestras.Sujeto] == suj & ...
%         [Muestras.EsDePractica] == 0 & ...
%         [Muestras.HayImagen] == 1 & ...
%         [Muestras.HaySonido] == 1 & ...
%         [Muestras.Delay] == -0.3 ...
%     ).AsinMedia];
% 
%     accuracy = [Muestras( ...
%         [Muestras.Sujeto] == suj & ...
%         [Muestras.EsDePractica] == 0 & ...
%         [Muestras.HayImagen] == 1 & ...
%         [Muestras.HaySonido] == 1 & ...
%         [Muestras.Delay] == -0.3 ...
%     ).Accuracy];
% 
% 
%     if numel(delta_c0) > 0
%         deltas{8}(mc5) = delta_c0(1);
%         m_accuracy{8}(mc5) = accuracy(1);
%         mc5 = mc5 + 1;
%     end
%     
%     %bloques combinados -0.1 y su accuracy
%      delta_c0 = [Muestras( ...
%         [Muestras.Sujeto] == suj & ...
%         [Muestras.EsDePractica] == 0 & ...
%         [Muestras.HayImagen] == 1 & ...
%         [Muestras.HaySonido] == 1 & ...
%         [Muestras.Delay] == -0.1 ...
%     ).AsinMedia];
% 
%     accuracy = [Muestras( ...
%         [Muestras.Sujeto] == suj & ...
%         [Muestras.EsDePractica] == 0 & ...
%         [Muestras.HayImagen] == 1 & ...
%         [Muestras.HaySonido] == 1 & ...
%         [Muestras.Delay] == -0.1 ...
%     ).Accuracy];
% 
% 
%     if numel(delta_c0) > 0
%         deltas{9}(mc6) = delta_c0(1);
%         m_accuracy{9}(mc6) = accuracy(1);
%         mc6 = mc6 + 1;
%     end
%     
    if ~isempty(deltas) 
        % figure;
        % plot(deltas,'r*');
        % plot(deltas);
        % title(['Sujeto ', num2str(suj)]);
    end
end

%Analisis de datos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Solo Sonido:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Distribucion de las muestras(histograma normalizado)

[f,x] = hist(deltas{1});
figure;
bar(x,f/sum(f))
title('Solo Sonido')



%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
%t = kstest(deltas{1})

%Boxplot
figure;
boxplot(deltas{1})
title('Boxplot tiempos de respuesta solo sonido')

%Medidas de centralidad
disp('prom')
mean(deltas{1})
median(deltas{1})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{1})

%Medidas de precision en la tarea
mean(m_accuracy{1})

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Solo imagen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Distribucion de las muestras(histograma normalizado)
[f,x] = hist(deltas{2});
figure;
bar(x,f/sum(f))
title('Solo imagen')
%Boxplot
figure;
boxplot(deltas{2})
title('Boxplot tiempos de respuesta solo imagen')

%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
%h = kstest(deltas{2})

%Medidas de centralidad
disp('prom')
mean(deltas{2})
median(deltas{2})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{2})

%Medidas de precision en la tarea
mean(m_accuracy{2})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Combinado +0:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Distribucion de las muestras(histograma normalizado)

[f,x] = hist(deltas{3});
figure;
bar(x,f/sum(f))
title('Delay +0')

%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
%t = kstest(deltas{3})

%Boxplot
figure;
boxplot(deltas{3})
title('Boxplot tiempos de respuesta Delay +0')

%Medidas de centralidad
disp('prom')
mean(deltas{3})
median(deltas{3})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{3})

%Medidas de precision en la tarea
mean(m_accuracy{3})

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Combinado +0.1:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Distribucion de las muestras(histograma normalizado)

[f,x] = hist(deltas{4});
figure;
bar(x,f/sum(f))
title('Delay + 0.1 target image')
%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
%t = kstest(deltas{4})

%Boxplot
figure;
boxplot(deltas{4})
title('Boxplot tiempos de respuesta Delay +0.1 target image')

%Medidas de centralidad
disp('prom')
mean(deltas{4})
median(deltas{4})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{4})

%Medidas de precision en la tarea
mean(m_accuracy{4})



%Analisis de datos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Combinado +0.3:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Distribucion de las muestras(histograma normalizado)

[f,x] = hist(deltas{5});
figure;
bar(x,f/sum(f))
title('Delay + 0.3 target image')
%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
%t = kstest(deltas{5})

%Boxplot
figure;
boxplot(deltas{5})
title('Boxplot tiempos de respuesta Delay 0+.3 target image')

%Medidas de centralidad
disp('prom')
mean(deltas{5})
median(deltas{5})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{5})

%Medidas de precision en la tarea
mean(m_accuracy{5})



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Combinado +0.4:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Distribucion de las muestras(histograma normalizado)

[f,x] = hist(deltas{6});
figure;
bar(x,f/sum(f))
title('Delay + 0.4 target image')
%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
t = kstest(deltas{6})

%Boxplot
figure;
boxplot(deltas{6})
title('Boxplot tiempos de respuesta Delay +0.4 target image')

%Medidas de centralidad
disp('prom')
mean(deltas{6})
median(deltas{6})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{6})

%Medidas de precision en la tarea
mean(m_accuracy{6})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Combinado +0.4 target sound:    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Distribucion de las muestras(histograma normalizado)

[f,x] = hist(deltas{7});
figure;
bar(x,f/sum(f))
title('Delay + 0.4 target sound')
%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
t = kstest(deltas{7})

%Boxplot
figure;
boxplot(deltas{7})
title('Boxplot tiempos de respuesta Delay +0.4 target sound')

%Medidas de centralidad
disp('prom')
mean(deltas{7})
median(deltas{7})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{7})

%Medidas de precision en la tarea
mean(m_accuracy{7})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Combinado +0.3 target sound:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Distribucion de las muestras(histograma normalizado)

[f,x] = hist(deltas{8});
figure;
bar(x,f/sum(f))
title('Delay + 0.3 target sound')

%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
t = kstest(deltas{8})

%Boxplot
figure;
boxplot(deltas{8})
title('Boxplot tiempos de respuesta Delay +0.3 target sound')

%Medidas de centralidad
disp('prom')
mean(deltas{8})
median(deltas{8})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{8})

%Medidas de precision en la tarea
mean(m_accuracy{8})

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Combinado +0.1 target sound:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Distribucion de las muestras(histograma normalizado)

[f,x] = hist(deltas{9});
figure;
bar(x,f/sum(f))
title('Delay + 0.1 target sound')

%One-sample Kolmogorov-Smirnov test, para ver normalidad en la muestra
t = kstest(deltas{9})

%Boxplot
figure;
boxplot(deltas{9})
title('Boxplot tiempos de respuesta Delay +0.1 target sonido')

%Medidas de centralidad
disp('prom')
mean(deltas{9})
median(deltas{9})

%Medidas de dispersion, estabilidad de la sincronia
var(deltas{9})

%Medidas de precision en la tarea
mean(m_accuracy{9})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Comparacion de los resultados:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[p,h] = ranksum(deltas{1},deltas{2})

delta_h0 =  abs(mean(deltas{1}) - mean(deltas{2}))

Permutation_Test(1000,deltas{1},deltas{2},delta_h0)

