d = {('v0','v2'):0.2,('v2','v0'):0.3,
     ('v2','v3'):0.1,('v3','v2'):0.4,
     ('v3','v7'):0.3,('v7','v3'):0.2,
     ('v3','v9'):0.5,('v9','v3'):0.1,
     ('v9','v4'):0.6,('v4','v9'):0.6,
     ('v9','v8'):0.1,('v8','v9'):0.2,
     ('v7','v1'):0.2,('v1','v7'):0.4,
     ('v2','v6'):0.2,('v6','v2'):0.2,
     ('v6','v5'):0.3,('v5','v6'):0.3}

R = ['v0', 'v1', 'v2', 'v3', 'v4', 'v5', 'v6', 'v7', 'v8', 'v9']
for e in R: 
    start = [(e, 1)]
    L = [e]
    while len(L) != 10:
        for i in d:
            for j in range(len(start)):
                if i[1] not in L and i[0] == start[j][0]:
                    start.append((i[1], d[i] * start[j][1]))
                    L.append(i[1])
    s = 0
    for i in start:
        s += i[1]
    print(f'if s = {e} and let w({e}) = 1, then the influence spreads = {s}')
