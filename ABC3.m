clc
clear

% Şehirlerin koordinatlarını tanımla (örnek)
cities = [40.5, 88.8;
          44.9, 39.2;
          36.6, 77;
          76.4, 39.7;
          62.8, 80.9;
          77.2, 75.6;
          93.3, 37.8;
          97.3, 21.7;
          19.3, 79.1;
          13.9, 95;
          69.7, 32.8;
          9.4, 67.2;
          52.6, 43.9;
          53.1, 83.4;
          86.2, 76.9;
          48.5, 16.8;
          39.4, 86.2;
          67.2, 99;
          74.2, 51.5;
          52.1, 88.5;
          34.8, 58.9;
          15, 15.5;
          58.7, 20;
          26.3, 40.7;
          4.5, 74.9;
          75.5, 82.6;
          24.3, 79;
          44.3, 31.9;
          68.8, 53.5;
          36, 9;
          73.7, 11.2;
          39.5, 13.7;
          68.4, 67.9;
          70.5, 49.6;
          44.3, 19;
          2, 49.6;
          33.1, 14.8;
          42.5, 5.5;
          27.1, 85.1;
          19.8, 56.1;
          82.2, 93;
          43, 69.7];

numCities = size(cities, 1);


% Mesafe matrisini oluştur
distanceMatrix = zeros(numCities);
for i = 1:numCities
    for j = 1:numCities
        distanceMatrix(i,j) = norm(cities(i,:) - cities(j,:));
    end
end

% ABC parametreleri
NP = 20;                 % Gıda kaynağı sayısı
MaxIter = 7000;         % Maksimum iterasyon sayısı
Limit = 40;              % Limit
D = numCities;           % Çözümün boyutu (şehir sayısı)

% Başlangıç popülasyonunu oluştur
pop = initialize_population(NP, D);
fitness = evaluate_population(pop, distanceMatrix); % Fitness hesapla
trial = zeros(1, NP);    % Her çözüm için deneme sayacı

% En iyi çözümü başlat
[bestFitness, bestIndex] = min(fitness);
bestSolution = pop(bestIndex, :);

% Algoritmanın ana döngüsü
for iter = 1:MaxIter
    % Çalışan arılar fazı
    for i = 1:NP
        % Çaprazlama işlemi: Mevcut çözüm (parent1) ile yeni çözüm (child) oluştur
        parent1 = pop(i,:);

        % Çözümü geçerli hale getirene kadar yeniden oluştur
        newSolution = Crossover(parent1, fitness, NP, pop, D); % Çaprazlama yapılır
        while ~check_constraint(newSolution, D-1)  % Kısıt kontrolü
            newSolution = Crossover(parent1, fitness, NP, pop, D); % Çaprazlama yapılır
        end

        newFitness = fitnesshesap(newSolution, distanceMatrix); % Fitness hesapla

        % Yeni çözüm ile mevcut çözüm karşılaştırılır
        if newFitness < fitness(i)
            pop(i,:) = newSolution;
            fitness(i) = newFitness;
            trial(i) = 0;  % İyileştirme varsa trial sıfırlanır
        else
            trial(i) = trial(i) + 1;  % İyileştirme yoksa trial artar
        end
    end

    totalFitness = sum(fitness);
    probability = fitness / totalFitness;

    for i = 1:NP
        if rand < probability(i)  % Eğer rastgele sayı, o çözümün olasılığına eşitse
            parent1 = pop(i,:);

            % Çözümü geçerli hale getirene kadar yeniden oluştur
            newSolution = Crossover(parent1, fitness, NP, pop, D); % Çaprazlama yapılır
            while ~check_constraint(newSolution, D-1)  % Kısıt kontrolü
                newSolution = Crossover(parent1, fitness, NP, pop, D); % Çaprazlama yapılır
            end

            newFitness = fitnesshesap(newSolution, distanceMatrix); % Fitness hesapla
            if newFitness < fitness(i)
                pop(i,:) = newSolution;
                fitness(i) = newFitness;
                trial(i) = 0;
            else
                trial(i) = trial(i) + 1;
            end
        end
    end

    % Kaşif arılar fazı (Limit kontrolü)
    for i = 1:NP
        if trial(i) >= Limit
            % Yeni rastgele çözüm oluştur
            newSolution = randperm(D);

            % Kısıt kontrolü yap
            while ~check_constraint(newSolution, D-1)
                newSolution = randperm(D);  % Geçerli çözüm bulana kadar yeniden rastgele çözüm oluştur
            end

            fitness(i) = fitnesshesap(newSolution, distanceMatrix);  % Yeni çözümün fitness'ını hesapla
            pop(i,:) = newSolution;  % Yeni çözümü popülasyona ekle
            trial(i) = 0;  % Deneme sayısını sıfırla
        end
    end

    % En iyi çözümü güncelle
    [currentBestFitness, currentBestIndex] = min(fitness);
    if currentBestFitness < bestFitness
        bestFitness = currentBestFitness;
        bestSolution = pop(currentBestIndex,:);
    end

    % İterasyon sonuçlarını göster
    fprintf('Iteration %d: Best Fitness = %.4f\n', iter, bestFitness);
end

% Sonuçları göster
disp('En iyi çözüm (şehir sırası):');
disp(bestSolution);
disp('En iyi fitness (toplam mesafe):');
disp(bestFitness);

function fitness = fitnesshesap(solution, distanceMatrix)
    % Verilen bir çözüm için fitness değeri hesaplanır
    n = length(solution);
    
    % Rotanın toplam uzunluğunu hesapla (D)
    D = 0;
    for i = 1:n-1
        D = D + distanceMatrix(solution(i), solution(i+1));
    end
    
    % En uzun mesafeyi (maxDist) ve en kısa mesafeyi (minDist) bul
    maxDist = -Inf;
    minDist = Inf;
    
    for i = 1:n-1
        dist = distanceMatrix(solution(i), solution(i+1));
        maxDist = max(maxDist, dist);
        minDist = min(minDist, dist);
    end
    
    % L'yi hesapla: maksimum mesafe * şehir sayısı
    L = maxDist * n;
    
    % Delta'yı hesapla
    Delta = maxDist - minDist;
    
    % Amaç fonksiyonu: L * Delta + D
    fitness = L * Delta + D;
end



% Popülasyonu başlatma fonksiyonu
function pop = initialize_population(NP, D)
    pop = zeros(NP, D);  % Popülasyonu başlat
    for i = 1:NP
        validSolution = false;
        while ~validSolution
            % 1. şehir başta, 22. şehir sonda, aradaki şehirler rastgele
            tempSolution = [1, randperm(D-2) + 1, D];  % 1. ve 22. şehri sabitle
            if check_constraint(tempSolution, D-1)  % Kısıt kontrolü yapılır
                validSolution = true;  % Geçerli çözüm bulundu
                pop(i,:) = tempSolution;  % Geçerli çözüm popülasyona eklenir
            end
        end
    end
end

% Popülasyonun fitness'ını değerlendirme fonksiyonu
function fitness = evaluate_population(pop, distanceMatrix)
    % Popülasyondaki her çözüm için fitness hesaplanır
    NP = size(pop, 1);  % Popülasyonun boyutu
    fitness = zeros(1, NP);  % Fitness vektörü
    for i = 1:NP
        fitness(i) = fitnesshesap(pop(i,:), distanceMatrix);  % Her bir çözüm için fitness hesaplanır
    end
end


function newSolution = Crossover(parent1, fitness, NP, pop, n)
    % Çaprazlama yapılacak noktalar seçilir
    point1 = randi(n-1);
    point2 = randi(n-1);
    
    % Eğer aynı noktayı seçersek, yeniden bir nokta seçiyoruz
    while point1 == point2
        point2 = randi(n-1);
    end

    % Kesişim noktalarındaki sırayı değiştirelim
    if point1 > point2
        temp = point1;
        point1 = point2;
        point2 = temp;
    end

    % İlk ebeveynden (parent1) bir şehir aralığı alalım
    child = -1 * ones(1, n); % -1, boş yerleri belirtir

    % Ebeveyn 1'den kesilen aralığı çocuk çözümüne kopyalayalım
    child(point1:point2) = parent1(point1:point2);  

    % Kalan şehirleri popülasyondan seçip child'a yerleştiriyoruz
    parent2 = pop(randi(NP), :);  % Popülasyondan rastgele bir ebeveyn seçiyoruz
    pos = point2 + 1; % Yeni ebeveynin şehri için yer açıyoruz
    
    for i = 1:n
        if ~ismember(parent2(i), child) % Eğer şehir child'ta yoksa
            if pos > n
                pos = 1;  % Eğer pozisyon n'yi geçtiyse, sıfırlıyoruz (dönerek devam ederiz)
            end
            child(pos) = parent2(i);
            pos = pos + 1;
        end
    end

    % Yeni çözümü döndürüyoruz
    newSolution = child;
end

function is_valid = check_constraint(solution, n)
    is_valid = true; % Varsayılan olarak geçerli kabul et
    
    % İlk şehir 1. indekste ve D. şehir D. indekste olmalı
    %if solution(1) ~= 1 || solution(n) ~= n
        %is_valid = false; % Eğer şart sağlanmazsa geçersiz kabul et
        %return;
    %end
    
    % Diğer kısıtları kontrol et
    for i = 1:length(solution) - 1
        % i çift, j tek ve i <= n/2 kontrolü
        if (mod(solution(i), 2) == 1 && mod(solution(i+1), 2) == 0 && solution(i) < (n-1)/2) || ...
           (mod(solution(i), 2) == 0 && mod(solution(i+1), 2) == 1 && solution(i) >= (n-1)/2)
            is_valid = false; % Geçerli çözüm değilse false döndür
            break;
        end
    end
end

